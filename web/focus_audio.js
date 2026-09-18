// FocusBell Web Audio engine.
//
// Two responsibilities:
//   1. Bell / alert tones (playFocusBellPattern) – short struck sounds built
//      from inharmonic partials, a strike transient and a touch of room.
//   2. Ambient soundscapes (focusAmbient*) – real-time rendering of the
//      declarative recipes defined in lib/core/audio/ambient_recipe.dart.
//      Noise beds are gapless looping AudioBufferSourceNodes, shaped by
//      BiquadFilters and slow LFOs; one-shot events (drops, crackles, thunder,
//      chirps) are scheduled ahead of time by a Poisson process so the sound
//      never repeats. lib/core/audio/ambient_renderer.dart is the offline
//      twin of this file for native platforms – keep the two in step.
(function () {
  'use strict';

  var NOISE_SECONDS = 6;
  var NOISE_RMS = 0.2;
  var NOISE_SEAM_SECONDS = 0.25;
  var EVENT_LOOKAHEAD_SECONDS = 1.6;
  var EVENT_TICK_MS = 400;
  var FADE_IN_SECONDS = 1.5;
  var FADE_OUT_SECONDS = 0.7;

  var ctx = null;
  // Per-context caches so the offline (test) contexts never share nodes with
  // the live one.
  var masters = new WeakMap();
  var bellBuses = new WeakMap();
  var noiseBufferCaches = new WeakMap();
  var ambient = null;

  // ------------------------------------------------------------ context

  function ensureContext() {
    if (!ctx || ctx.state === 'closed') {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (ctx.state === 'suspended') {
      ctx.resume();
    }
    return ctx;
  }

  // Soft-knee limiter shared by bells and ambience: linear up to 0.6, then a
  // tanh knee that never reaches 1.0. Same curve as AmbientRenderer._softLimit
  // so both engines clip identically. (A DynamicsCompressor was rejected –
  // its automatic make-up gain shifted every soundscape by about +5 dB.)
  function getMaster(context) {
    var master = masters.get(context);
    if (master) {
      return master;
    }
    var shaper = context.createWaveShaper();
    var size = 4097;
    var curve = new Float32Array(size);
    for (var i = 0; i < size; i++) {
      var x = (i / (size - 1)) * 2 - 1;
      var magnitude = Math.abs(x);
      var y = magnitude;
      if (magnitude > 0.6) {
        y = 0.6 + 0.4 * Math.tanh((magnitude - 0.6) / 0.4);
      }
      curve[i] = x < 0 ? -y : y;
    }
    shaper.curve = curve;
    shaper.oversample = '2x';
    shaper.connect(context.destination);
    masters.set(context, shaper);
    return shaper;
  }

  ['click', 'touchstart', 'keydown'].forEach(function (evt) {
    document.addEventListener(evt, function unlock() {
      try {
        ensureContext();
      } catch (e) {}
      document.removeEventListener(evt, unlock);
    }, { once: true });
  });

  // -------------------------------------------------------------- noise

  function makeNoiseGenerator(color) {
    var b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0, brown = 0;
    return function () {
      var white = Math.random() * 2 - 1;
      if (color === 'white') {
        return white;
      }
      if (color === 'brown') {
        brown = (brown + 0.02 * white) / 1.02;
        return brown;
      }
      // Paul Kellet's pink noise filter.
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.96900 * b2 + white * 0.1538520;
      b3 = 0.86650 * b3 + white * 0.3104856;
      b4 = 0.55000 * b4 + white * 0.5329522;
      b5 = -0.7616 * b5 - white * 0.0168980;
      var pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
      b6 = white * 0.115926;
      return pink;
    };
  }

  function fillNoise(channel, color, sampleRate) {
    var next = makeNoiseGenerator(color);
    // Let the recursive filters settle before recording.
    for (var i = 0; i < 4096; i++) {
      next();
    }
    var sum = 0;
    for (var n = 0; n < channel.length; n++) {
      var v = next();
      channel[n] = v;
      sum += v * v;
    }
    var scale = NOISE_RMS / Math.sqrt(sum / channel.length);
    for (var k = 0; k < channel.length; k++) {
      channel[k] *= scale;
    }
    // Equal-power cross-fade of the tail into the head so the buffer loops
    // without a click even for bass-heavy brown noise.
    var seam = Math.min(Math.floor(sampleRate * NOISE_SEAM_SECONDS), channel.length >> 2);
    var length = channel.length;
    for (var s = 0; s < seam; s++) {
      var phase = (s / seam) * Math.PI / 2;
      var head = channel[s];
      var tail = channel[length - seam + s];
      channel[s] = head * Math.sin(phase) + tail * Math.cos(phase);
    }
    // The blended head now differs from the untouched tail; shorten the
    // playable region so the loop point lands where head === tail.
    return length - seam;
  }

  // Returns { buffer, loopEnd } – a stereo buffer with two independent noise
  // channels (beds) or a mono one (events).
  function getNoiseBuffer(context, color, channels) {
    var key = color + ':' + channels;
    var cache = noiseBufferCaches.get(context);
    if (!cache) {
      cache = {};
      noiseBufferCaches.set(context, cache);
    }
    if (cache[key]) {
      return cache[key];
    }
    var frames = Math.floor(NOISE_SECONDS * context.sampleRate);
    var buffer = context.createBuffer(channels, frames, context.sampleRate);
    var loopEnd = frames / context.sampleRate;
    for (var c = 0; c < channels; c++) {
      var playable = fillNoise(buffer.getChannelData(c), color, context.sampleRate);
      loopEnd = playable / context.sampleRate;
    }
    var entry = { buffer: buffer, loopEnd: loopEnd };
    cache[key] = entry;
    return entry;
  }

  function startNoiseSource(context, color, channels, startAt) {
    var entry = getNoiseBuffer(context, color, channels);
    var source = context.createBufferSource();
    source.buffer = entry.buffer;
    source.loop = true;
    source.loopStart = 0;
    source.loopEnd = entry.loopEnd;
    source.start(startAt, Math.random() * entry.loopEnd);
    return source;
  }

  // ------------------------------------------------------------ helpers

  function applyFilter(filter, type, frequency, q, context) {
    filter.type = type;
    var maxFrequency = context.sampleRate / 2 - 100;
    filter.frequency.value = Math.min(Math.max(frequency, 20), maxFrequency);
    // Web Audio expresses low/high-pass resonance in dB, band-pass as a
    // linear Q. Recipes always use linear Q (RBJ convention).
    filter.Q.value = type === 'bandpass' ? q : 20 * Math.log10(Math.max(q, 0.1));
  }

  // Sine LFO with a random start phase so layers sharing a rate do not move
  // in lock-step (mirrors the random phases of the offline renderer).
  function createLfo(context, rateHz, startAt) {
    var osc = context.createOscillator();
    var phase = Math.random() * Math.PI * 2;
    osc.setPeriodicWave(context.createPeriodicWave(
      new Float32Array([0, Math.sin(phase)]),
      new Float32Array([0, Math.cos(phase)])
    ));
    osc.frequency.value = rateHz;
    osc.start(startAt);
    return osc;
  }

  function connectScaled(context, source, amount, param) {
    var scale = context.createGain();
    scale.gain.value = amount;
    source.connect(scale);
    scale.connect(param);
    return scale;
  }

  // Two LFOs at incommensurate rates (rate, rate * 0.7317) weighted 0.6 / 0.4
  // sum to a signal in [-1, 1] that never settles into an obvious period.
  function attachLfo(context, lfoSpec, startAt, gainNode, baseGain, filterNode, session) {
    if (!lfoSpec || (!lfoSpec.depth && !lfoSpec.filterSweepHz)) {
      gainNode.gain.value = baseGain;
      return;
    }
    var depth = lfoSpec.depth || 0;
    var sweep = lfoSpec.filterSweepHz || 0;
    var lfoA = createLfo(context, lfoSpec.rateHz, startAt);
    var lfoB = createLfo(context, lfoSpec.rateHz * 0.7317, startAt);
    session.sources.push(lfoA, lfoB);
    gainNode.gain.value = baseGain * (1 - depth / 2);
    if (depth > 0) {
      connectScaled(context, lfoA, baseGain * depth / 2 * 0.6, gainNode.gain);
      connectScaled(context, lfoB, baseGain * depth / 2 * 0.4, gainNode.gain);
    }
    if (sweep && filterNode) {
      connectScaled(context, lfoA, sweep * 0.6, filterNode.frequency);
      connectScaled(context, lfoB, sweep * 0.4, filterNode.frequency);
    }
  }

  // Stereo (noise) layers skip the panner at centre – the stereo law is the
  // identity there. Mono sources always get one so they sit at -3 dB per side
  // like the offline renderer's equal-power pan.
  function panNode(context, pan, mono) {
    if ((!pan && !mono) || !context.createStereoPanner) {
      return null;
    }
    var panner = context.createStereoPanner();
    panner.pan.value = Math.max(-1, Math.min(1, pan || 0));
    return panner;
  }

  function randomBetween(min, max) {
    return min + (max - min) * Math.random();
  }

  function logUniform(min, max) {
    if (min <= 0 || max <= min) {
      return min;
    }
    return Math.exp(randomBetween(Math.log(min), Math.log(max)));
  }

  function exponentialGap(rate) {
    return -Math.log(1 - Math.random()) / rate;
  }

  // ------------------------------------------------------------- layers

  function buildNoiseLayer(context, layer, session, startAt, bus) {
    var source = startNoiseSource(context, layer.color, 2, startAt);
    session.sources.push(source);

    // Stereo width: right = mix of the left noise and an independent noise.
    var width = Math.max(0, Math.min(1, layer.width == null ? 0.8 : layer.width));
    var norm = 1 / Math.sqrt((1 - width) * (1 - width) + width * width);
    var splitter = context.createChannelSplitter(2);
    var merger = context.createChannelMerger(2);
    source.connect(splitter);
    splitter.connect(merger, 0, 0);
    var leftIntoRight = context.createGain();
    leftIntoRight.gain.value = (1 - width) * norm;
    splitter.connect(leftIntoRight, 0);
    leftIntoRight.connect(merger, 0, 1);
    var rightIntoRight = context.createGain();
    rightIntoRight.gain.value = width * norm;
    splitter.connect(rightIntoRight, 1);
    rightIntoRight.connect(merger, 0, 1);

    var node = merger;
    var lastFilter = null;
    (layer.filters || []).forEach(function (spec) {
      var filter = context.createBiquadFilter();
      applyFilter(filter, spec.type, spec.frequency, spec.q, context);
      node.connect(filter);
      node = filter;
      lastFilter = filter;
    });

    var gain = context.createGain();
    attachLfo(context, layer.lfo, startAt, gain, layer.gain, lastFilter, session);
    node.connect(gain);

    var panner = panNode(context, layer.pan);
    if (panner) {
      gain.connect(panner);
      panner.connect(bus);
    } else {
      gain.connect(bus);
    }
  }

  function buildToneLayer(context, layer, session, startAt, bus) {
    var gain = context.createGain();
    var depth = layer.tremoloDepth || 0;
    if (layer.tremoloRateHz > 0 && depth > 0) {
      gain.gain.value = layer.gain * (1 - depth / 2);
      var tremolo = createLfo(context, layer.tremoloRateHz, startAt);
      session.sources.push(tremolo);
      connectScaled(context, tremolo, layer.gain * depth / 2, gain.gain);
    } else {
      gain.gain.value = layer.gain;
    }

    var beat = layer.binauralBeatHz || 0;
    var detune = Math.pow(2, (layer.detuneCents || 0) / 1200);
    var sides = beat > 0
      ? [{ frequency: layer.frequency, pan: -1 }, { frequency: layer.frequency + beat, pan: 1 }]
      : [{ frequency: layer.frequency, pan: layer.pan || 0 }];

    sides.forEach(function (side) {
      var sideBus = context.createGain();
      sideBus.gain.value = 1;
      (layer.partials || [{ ratio: 1, gain: 1 }]).forEach(function (partial) {
        var base = side.frequency * partial.ratio;
        var voices = layer.detuneCents > 0
          ? [[base * detune, partial.gain / 2], [base / detune, partial.gain / 2]]
          : [[base, partial.gain]];
        voices.forEach(function (voice) {
          var osc = context.createOscillator();
          osc.type = 'sine';
          osc.frequency.value = voice[0];
          var partialGain = context.createGain();
          partialGain.gain.value = voice[1];
          osc.connect(partialGain);
          partialGain.connect(sideBus);
          osc.start(startAt);
          session.sources.push(osc);
        });
      });
      var panner = panNode(context, side.pan, true);
      if (panner) {
        sideBus.connect(panner);
        panner.connect(gain);
      } else {
        sideBus.connect(gain);
      }
    });

    gain.connect(bus);
  }

  function scheduleEvent(context, layer, at, session) {
    var duration = randomBetween(layer.minDurationSeconds, layer.maxDurationSeconds);
    var attack = Math.max(0.002, duration * (layer.attackRatio || 0.1));
    var startFrequency = logUniform(layer.minFrequency, layer.maxFrequency);
    var endFrequency = startFrequency * (layer.sweepRatio || 1);
    var gainValue = Math.max(0.0001,
      layer.gain * (1 - (layer.gainJitter || 0) * Math.random()));
    var stopAt = at + duration + 0.05;

    var envelope = context.createGain();
    envelope.gain.setValueAtTime(0, at);
    envelope.gain.linearRampToValueAtTime(gainValue, at + attack);
    envelope.gain.exponentialRampToValueAtTime(gainValue * 0.001, at + duration);

    var output = envelope;
    var panner = panNode(context, randomBetween(-layer.panSpread, layer.panSpread), true);
    if (panner) {
      envelope.connect(panner);
      output = panner;
    }
    output.connect(session.bus);

    var nodes = [];
    if (layer.sound === 'burst') {
      var source = startNoiseSource(context, layer.color, 1, at);
      var filter = context.createBiquadFilter();
      applyFilter(filter, layer.filterType, startFrequency, layer.q, context);
      if (endFrequency !== startFrequency) {
        filter.frequency.setValueAtTime(startFrequency, at);
        filter.frequency.exponentialRampToValueAtTime(
          Math.max(20, endFrequency), at + duration);
      }
      source.connect(filter);
      filter.connect(envelope);
      source.stop(stopAt);
      nodes.push(source);
    } else {
      var trillTarget = envelope;
      if (layer.trillHz > 0) {
        var trill = context.createGain();
        trill.gain.value = 0.5;
        var trillOsc = context.createOscillator();
        trillOsc.frequency.value = layer.trillHz;
        connectScaled(context, trillOsc, 0.5, trill.gain);
        trillOsc.start(at);
        trillOsc.stop(stopAt);
        trill.connect(envelope);
        trillTarget = trill;
        nodes.push(trillOsc);
      }
      (layer.partials || [{ ratio: 1, gain: 1 }]).forEach(function (partial) {
        var osc = context.createOscillator();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(startFrequency * partial.ratio, at);
        if (endFrequency !== startFrequency) {
          osc.frequency.exponentialRampToValueAtTime(endFrequency * partial.ratio, at + duration);
        }
        var partialGain = context.createGain();
        partialGain.gain.value = partial.gain;
        osc.connect(partialGain);
        partialGain.connect(trillTarget);
        osc.start(at);
        osc.stop(stopAt);
        nodes.push(osc);
      });
    }

    // Release the whole one-shot sub-graph once its last source has ended.
    nodes[nodes.length - 1].onended = function () {
      try {
        output.disconnect();
        envelope.disconnect();
      } catch (e) {}
    };
  }

  function scheduleEventsUntil(context, session, horizon) {
    var now = context.currentTime;
    session.eventStates.forEach(function (state) {
      // A throttled background tab may wake up late; skip the backlog rather
      // than firing every missed event at once.
      if (state.nextAt < now - 1) {
        state.nextAt = now + 0.05;
      }
      var guard = 0;
      while (state.nextAt < horizon && guard++ < 200) {
        scheduleEvent(context, state.layer, state.nextAt, session);
        state.nextAt += Math.max(state.layer.minGapSeconds || 0,
          exponentialGap(state.layer.ratePerSecond));
      }
    });
  }

  function buildSession(context, recipe, startAt, destination) {
    var session = {
      context: context,
      sources: [],
      eventStates: [],
      timer: null,
      paused: false,
      stopped: false
    };
    session.fade = context.createGain();
    session.volume = context.createGain();
    session.bus = context.createGain();
    session.bus.gain.value = recipe.masterGain || 1;
    session.bus.connect(session.fade);
    session.fade.connect(session.volume);
    session.volume.connect(destination);

    (recipe.layers || []).forEach(function (layer) {
      if (layer.kind === 'noise') {
        buildNoiseLayer(context, layer, session, startAt, session.bus);
      } else if (layer.kind === 'tone') {
        buildToneLayer(context, layer, session, startAt, session.bus);
      } else if (layer.kind === 'event' && layer.ratePerSecond > 0) {
        session.eventStates.push({
          layer: layer,
          nextAt: startAt + exponentialGap(layer.ratePerSecond) * 0.5
        });
      }
    });
    return session;
  }

  function teardownSession(session) {
    if (session.timer) {
      clearInterval(session.timer);
      session.timer = null;
    }
    session.stopped = true;
    session.sources.forEach(function (source) {
      try {
        source.stop();
      } catch (e) {}
    });
    try {
      session.volume.disconnect();
    } catch (e) {}
  }

  // ------------------------------------------------------------- public

  window.focusAmbientPlay = function (recipeJson, volume) {
    try {
      var context = ensureContext();
      var recipe = typeof recipeJson === 'string' ? JSON.parse(recipeJson) : recipeJson;
      window.focusAmbientStop();

      var now = context.currentTime;
      var session = buildSession(context, recipe, now, getMaster(context));
      session.volume.gain.value = Math.max(0, Math.min(1, volume));
      session.fade.gain.setValueAtTime(0, now);
      session.fade.gain.linearRampToValueAtTime(1, now + FADE_IN_SECONDS);

      scheduleEventsUntil(context, session, now + EVENT_LOOKAHEAD_SECONDS);
      session.timer = setInterval(function () {
        if (session.stopped || session.paused) {
          return;
        }
        scheduleEventsUntil(context, session, context.currentTime + EVENT_LOOKAHEAD_SECONDS);
      }, EVENT_TICK_MS);
      ambient = session;
    } catch (e) {
      console.warn('focusAmbientPlay error:', e);
    }
  };

  window.focusAmbientStop = function () {
    var session = ambient;
    if (!session) {
      return;
    }
    ambient = null;
    try {
      var now = session.context.currentTime;
      session.fade.gain.cancelScheduledValues(now);
      session.fade.gain.setValueAtTime(session.fade.gain.value, now);
      session.fade.gain.linearRampToValueAtTime(0, now + FADE_OUT_SECONDS);
      if (session.timer) {
        clearInterval(session.timer);
        session.timer = null;
      }
      setTimeout(function () {
        teardownSession(session);
      }, FADE_OUT_SECONDS * 1000 + 100);
    } catch (e) {
      teardownSession(session);
    }
  };

  window.focusAmbientPause = function () {
    var session = ambient;
    if (!session || session.paused) {
      return;
    }
    session.paused = true;
    var now = session.context.currentTime;
    session.fade.gain.cancelScheduledValues(now);
    session.fade.gain.setValueAtTime(session.fade.gain.value, now);
    session.fade.gain.linearRampToValueAtTime(0, now + 0.4);
  };

  window.focusAmbientResume = function () {
    var session = ambient;
    if (!session || !session.paused) {
      return;
    }
    ensureContext();
    session.paused = false;
    var now = session.context.currentTime;
    session.eventStates.forEach(function (state) {
      state.nextAt = now + exponentialGap(state.layer.ratePerSecond) * 0.5;
    });
    session.fade.gain.cancelScheduledValues(now);
    session.fade.gain.setValueAtTime(session.fade.gain.value, now);
    session.fade.gain.linearRampToValueAtTime(1, now + 1.0);
  };

  window.focusAmbientSetVolume = function (volume) {
    var session = ambient;
    if (!session) {
      return;
    }
    var now = session.context.currentTime;
    session.volume.gain.setTargetAtTime(Math.max(0, Math.min(1, volume)), now, 0.05);
  };

  window.focusAmbientIsPlaying = function () {
    return !!ambient && !ambient.paused;
  };

  // Diagnostic: RMS of what the live ambient session is currently sending to
  // the speakers (0 when nothing plays). Used by end-to-end tests.
  var meter = null;
  window.focusAmbientMeter = function () {
    var session = ambient;
    if (!session || !ctx) {
      return 0;
    }
    if (!meter || meter.session !== session) {
      var analyser = ctx.createAnalyser();
      analyser.fftSize = 2048;
      session.volume.connect(analyser);
      meter = { session: session, analyser: analyser, data: new Float32Array(2048) };
    }
    meter.analyser.getFloatTimeDomainData(meter.data);
    var sum = 0;
    for (var i = 0; i < meter.data.length; i++) {
      sum += meter.data[i] * meter.data[i];
    }
    return Math.sqrt(sum / meter.data.length);
  };

  // Renders a recipe with an OfflineAudioContext. Used by tests to inspect
  // the exact signal the browser would produce (levels, clicks, spectrum).
  window.focusAmbientRenderOffline = function (recipeJson, seconds, sampleRate) {
    var recipe = typeof recipeJson === 'string' ? JSON.parse(recipeJson) : recipeJson;
    var rate = sampleRate || 44100;
    var offline = new OfflineAudioContext(2, Math.floor(seconds * rate), rate);
    var session = buildSession(offline, recipe, 0, getMaster(offline));
    session.volume.gain.value = 1;
    session.fade.gain.value = 1;
    scheduleEventsUntil(offline, session, seconds);
    return offline.startRendering();
  };

  // --------------------------------------------------------------- bell

  // [ratio, gain, decay multiplier, detune cents]
  var BELL_VOICES = {
    bowl: [[1, 1, 1, 3], [2.02, 0.45, 0.7, 0], [3.01, 0.22, 0.5, 0], [4.4, 0.1, 0.35, 0]],
    chime: [[1, 0.9, 1, 2], [2.76, 0.5, 0.6, 0], [5.4, 0.25, 0.4, 0], [8.9, 0.1, 0.25, 0]],
    crystal: [[1, 0.8, 1, 4], [2.7, 0.45, 0.75, 0], [5.1, 0.25, 0.5, 0], [7.9, 0.1, 0.35, 0]],
    wood: [[0.78, 1, 1, 0], [1.9, 0.3, 0.6, 0], [3.1, 0.12, 0.4, 0]],
    water: [[1, 1, 1, 0], [2.2, 0.2, 0.6, 0]],
    digital: [[1, 1, 1, 0], [2, 0.3, 0.8, 0], [3, 0.1, 0.5, 0]],
    pulse: [[1, 0.9, 1, 0], [2, 0.25, 0.7, 0]],
    breath: [[1, 0.5, 1, 0], [0.5, 0.15, 0.9, 0]],
    harp: [[1, 1, 1, 3], [2, 0.5, 0.6, 0], [3, 0.25, 0.4, 0], [4, 0.12, 0.3, 0], [5, 0.06, 0.25, 0]]
  };

  // Strike transient: [filter type, frequency multiplier or absolute Hz, Q, length s, gain]
  var BELL_STRIKES = {
    bowl: ['lowpass', 400, 0.7, 0.04, 0.25],
    chime: ['bandpass', -4, 2, 0.015, 0.2],
    crystal: ['bandpass', 6000, 2, 0.01, 0.12],
    wood: ['bandpass', 1800, 1, 0.012, 0.5],
    water: ['bandpass', 3000, 3, 0.008, 0.15],
    harp: ['highpass', 2000, 0.7, 0.008, 0.15]
  };

  var BELL_ATTACK = { bowl: 0.008, breath: 0.35, digital: 0.003, pulse: 0.002 };

  // Bell bus: soft high-shelf roll-off plus a short feedback delay for a hint
  // of room, so struck tones do not sound like bare oscillators.
  function getBellBus(context) {
    var cached = bellBuses.get(context);
    if (cached) {
      return cached;
    }
    var input = context.createGain();
    var tone = context.createBiquadFilter();
    tone.type = 'lowpass';
    tone.frequency.value = 6500;
    tone.Q.value = -3;
    input.connect(tone);
    tone.connect(getMaster(context));

    var delay = context.createDelay(0.5);
    delay.delayTime.value = 0.09;
    var feedback = context.createGain();
    feedback.gain.value = 0.25;
    var damp = context.createBiquadFilter();
    damp.type = 'lowpass';
    damp.frequency.value = 3000;
    var wet = context.createGain();
    wet.gain.value = 0.18;
    tone.connect(delay);
    delay.connect(damp);
    damp.connect(feedback);
    feedback.connect(delay);
    damp.connect(wet);
    wet.connect(getMaster(context));
    bellBuses.set(context, input);
    return input;
  }

  function strike(context, texture, frequency, volume, startAt, length, bus) {
    var voices = BELL_VOICES[texture] || BELL_VOICES.digital;
    var attack = BELL_ATTACK[texture] || 0.002;
    var attackSeconds = attack >= 0.1 ? length * attack : attack;
    var glide = texture === 'water' ? 0.78 : 1;

    voices.forEach(function (voice) {
      var detune = Math.pow(2, voice[3] / 1200);
      var pair = voice[3] > 0 ? [detune, 1 / detune] : [1];
      pair.forEach(function (ratio) {
        var osc = context.createOscillator();
        osc.type = texture === 'pulse' && voice[0] === 1 ? 'triangle' : 'sine';
        var f = frequency * voice[0] * ratio;
        osc.frequency.setValueAtTime(f, startAt);
        if (glide !== 1) {
          osc.frequency.exponentialRampToValueAtTime(f * glide, startAt + length * voice[2]);
        }
        var gain = context.createGain();
        var peak = Math.max(volume * voice[1] / pair.length, 0.0005);
        gain.gain.setValueAtTime(0, startAt);
        gain.gain.linearRampToValueAtTime(peak, startAt + attackSeconds);
        gain.gain.exponentialRampToValueAtTime(0.0005, startAt + attackSeconds + length * voice[2]);
        osc.connect(gain);
        gain.connect(bus);
        osc.start(startAt);
        osc.stop(startAt + attackSeconds + length * voice[2] + 0.05);
      });
    });

    var strikeSpec = BELL_STRIKES[texture];
    if (texture === 'breath') {
      strikeSpec = ['bandpass', -2, 1.5, length * 0.9, 0.6];
    }
    if (strikeSpec) {
      var source = startNoiseSource(context, texture === 'breath' ? 'pink' : 'white', 1, startAt);
      var filter = context.createBiquadFilter();
      var f0 = strikeSpec[1] < 0 ? frequency * -strikeSpec[1] : strikeSpec[1];
      applyFilter(filter, strikeSpec[0], f0, strikeSpec[2], context);
      var env = context.createGain();
      var strikeAttack = texture === 'breath' ? strikeSpec[3] * 0.4 : 0.001;
      env.gain.setValueAtTime(0, startAt);
      env.gain.linearRampToValueAtTime(Math.max(volume * strikeSpec[4], 0.0005), startAt + strikeAttack);
      env.gain.exponentialRampToValueAtTime(0.0005, startAt + strikeSpec[3]);
      source.connect(filter);
      filter.connect(env);
      env.connect(bus);
      source.stop(startAt + strikeSpec[3] + 0.05);
    }
  }

  function scheduleBellPattern(context, bus, frequency, duration, volume, texture, pulseCount, startAt) {
    // Partials stack up to ~1.8x, keep the summed peak under the limiter.
    var safeVolume = Math.max(volume, 0.001) * 0.55;
    var safeTexture = texture || 'digital';
    var pulses = Math.max(1, pulseCount || 1);
    var pulseGap = Math.max(0.14, duration / (pulses + 1.8));
    for (var index = 0; index < pulses; index++) {
      var gainScale = Math.max(0.55, 1 - index * 0.12);
      strike(context, safeTexture, frequency, safeVolume * gainScale,
        startAt + index * pulseGap, duration, bus);
    }
  }

  window.playFocusBellPattern = function (frequency, duration, volume, texture, pulseCount) {
    try {
      var context = ensureContext();
      scheduleBellPattern(context, getBellBus(context), frequency, duration, volume,
        texture, pulseCount, context.currentTime + 0.02);
    } catch (e) {
      console.warn('playFocusBellPattern error:', e);
    }
  };

  // Offline twin of playFocusBellPattern for tests.
  window.focusBellRenderOffline = function (frequency, duration, volume, texture, pulseCount, seconds) {
    var rate = 44100;
    var offline = new OfflineAudioContext(2, Math.floor((seconds || duration + 1.5) * rate), rate);
    scheduleBellPattern(offline, getBellBus(offline), frequency, duration, volume, texture, pulseCount, 0.02);
    return offline.startRendering();
  };
})();
