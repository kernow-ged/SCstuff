(
var maj_pent = #[0, 2, 4, 7, 9];
var min_pent = #[-3, 0, 2, 4, 7];

var maj2maj = #[3, 4, 5, 7, 8, 9];
var min2min = #[3, 4, 5, 7, 8, 9];
var maj2min = #[8, 10];
var min2maj = #[2, 4];

var degseq = [];
var durseq = [];
var noteseq = [];
var basechord = [];
var cp = [[],[],[]];

var totalduration = 0;

// three tweakable globals
var tempomultiplier = 0.25; // 0.0 < x,     the smaller, the faster
var chordsus = 1.0;    // 0.0 < x <= 1.0,   how long the underpinning chord lasts
var rptmodifier = 0.8; // 0.0 <= x <= 1.0,  the larger, the more tendency to repeat generated phrases

var tonality = "major";
var key = 0;  // 0 = C, 1 = C#... 11 = B, u know the score
var base = 60;

var oldnote = [-1, -1, -1];  // one for each of 3 voices
var oldinterval = [3, 5, 8];

// ratio tuning
var offsets = [1, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 16/9, 15/8].ratiomidi - (0..11);
var globaltuning = (0..127);
var tune_x= [];

var retune_all = {
    arg newkey, deviations_from_ET;
    var tuning, interval;
    interval = (newkey - key) % 12;
    globaltuning = globaltuning + deviations_from_ET[interval];
	// ^ this tracks the global 'drift' in pitch through many key changes
    key = newkey;
    tuning = globaltuning + deviations_from_ET.rotate(newkey);
};

var gen_interval = {
	arg note, index;
	var interval;
	if(note > oldnote[index],
		{
			switch (oldinterval[index],
			3, {interval = 8},
			5, {interval = 3},
			8, {interval = 5}
		    );
		},
		{
			switch (oldinterval[index],
			3, {interval = 5},
			5, {interval = 8},
			8, {interval = 3}
		    );
		}
	);
	if(note == oldnote[index],
		{interval = oldinterval[index]},
		{oldinterval[index] = interval;}
	);
	oldnote[index] = note;
	interval;
};

var reroll_seq = {
	var no_events = [2,4,8,16].wchoose([0.125, 0.125, 0.5, 0.25]) + [0,3,5,7].wchoose([0.5, 0.125, 0.125, 0.25]);
	var tripletise = [1, 0.66].wchoose([0.9, 0.1]);
	var invertchord = [0, 12].wchoose([0.9, 0.1]);
	if( tonality == "major",
		{degseq = [0]; basechord = [0,4]; (no_events-1).do({degseq = degseq ++ maj_pent.choose})},
		{degseq = [-3]; basechord = [-3,0]; (no_events-1).do({degseq = degseq ++ min_pent.choose})}
    );
	basechord[0] = basechord[0] + invertchord;
    durseq = [1];
	(no_events-1).do({durseq = durseq ++ [0.5, 1].wchoose([0.25, 0.75])});
	durseq = durseq * tripletise;
	tempomultiplier = tempomultiplier * [1.0, 0.99, 1.01].wchoose([0.8, 0.1, 0.1]);
	durseq = durseq * tempomultiplier;
	totalduration = durseq.sum;
};

var gen_voices = {
	var minors = [-3, 2, 4, 9];
	var third;
	noteseq = degseq + base + key;
	basechord = basechord + base + key;
	for (0, (cp.size -1), {
		arg x;
	    cp[x] = [];
	    for (0, (noteseq.size - 1), {
	        arg i;
		    if( minors.indexOf(degseq[i]) == nil,
			    {third = 4},
			    {third = 3}
		    );
		    switch (gen_interval.value(noteseq[i], x),
				3, {cp[x] = cp[x] ++ (noteseq[i] + third) },
				5, {cp[x] = cp[x] ++ (noteseq[i] + 7) },
				8, {cp[x] = cp[x] ++ (noteseq[i] + 12) }
		    );
	    });
      });
};

var reroll = {
	var newkey;
	var changetonality = [0, 1].wchoose([0.7, 0.3]);
	switch( changetonality,
		0, {
			if(tonality == "major",
				{newkey = key + maj2maj.choose;},
				{newkey = key + min2min.choose;}
			);
		},
		1, {
			if(tonality == "major",
				{newkey = key + maj2min.choose; tonality = "minor";},
				{newkey = key + min2maj.choose; tonality = "major";}
			);
		}
	);
	// now change the key
	newkey = newkey % 12;
	tune_x = retune_all.value(newkey, offsets);
	reroll_seq.value; // actually ~totalduration
	gen_voices.value;
	for(0, (noteseq.size - 1), {
		arg i;
	    noteseq[i] = tune_x[noteseq[i]];
		for(0, (cp.size -1), {
			arg j;
			cp[j][i] = [tune_x[cp[j][i]], \rest].wchoose([0.8, 0.2]);
		});
     });
    for(0, (basechord.size - 1), {
		arg i;
	    basechord[i] = tune_x[basechord[i]];
	    }
    );
};

var play_bar = {
	var x = (((23 - noteseq.size)/23) * rptmodifier);
	var t = [0, 1].wchoose([x, (1.0 - x)]);
	switch (t,
		{0},{
			// repeat last but switch parts around randomly
			cp.swap([0,1,2].choose, [0,1,2].choose);
			basechord[1] = [basechord[1], (basechord[0] + 7), (basechord[0] + 12)].choose;
		},
		{1},{reroll.value}
	);
	Pbind(
		\out, bus,
		\instrument, "wow",
		\rel, 2,
		\mutedString, Pwhite(0.05, 0.1), // see it just ignores params that it hasn't got
		\amp, Pwhite(0.08, 0.12),
		\legato, 0.7,
		\midinote,  Pseq([basechord], 1),
		\dur, totalduration * chordsus,
		\pan, Pwhite(-0.2, -0.3)
	).play;
    Pbind(
		\out, bus,
		\instrument, "pluck",
		\decay, Pwhite(7.0, 8.0),
		\mutedString, Pwhite(0.05, 0.1),
		\amp, 0.1,
		\legato, 0.4,
		\midinote,  Pseq(noteseq, 1),
		//\midinote,  Pseq(cp[2], 1),
		\dur, Pseq(durseq),
		\pan, Pwhite(-0.4, -0.7)
	).play;
   Pbind(
		\out, bus,
		\instrument, "laserbeam",
		\decay, Pwhite(7.0, 8.0),
		\att, Pwhite(0.01, 0.03),
		\amp, 0.1,
		\legato, 0.6,
		\midinote,  Pseq(cp[0], 1),
		\dur, Pseq(durseq),
		\pan, Pwhite(0.4, 0.7)
	).play;
   Pbind(
		\out, bus,
		\instrument, "trianglewavebells",
		\decay, Pwhite(7.0, 8.0),
		//\cutoff, Pwhite(75, 125),
		\rq, Pwhite(0.5, 0.8),
		\amp, 0.1,
		\legato, 0.6,
		\midinote,  Pseq(cp[1], 1),
		\dur, Pseq(durseq),
		\pan, Pwhite(0.2, 0.4)
	).play;
   Pbind(
		\out, bus,
		\instrument, "moogbass",
		\decay, Pwhite(7.0, 8.0),
		\mutedString, Pwhite(0.05, 0.1),
		\cutoff, Pbrown(500, 1000, 50),
		\lagamount, Pbrown(0.01, 0.08, 0.01),
		\att, Pwhite(0.001, 0.010),
		\chorus, Pwhite(0.6, 0.9),
		\amp, 0.1,
		\legato, 0.6,
		\midinote,  Pseq(cp[2] - 24.0 , 1),
		//\midinote,  Pseq(noteseq - 24.0 , 1),
		\dur, Pseq(durseq),
		\pan, 0
	).play;
	// line up the next iteration
	SystemClock.sched(totalduration, {play_bar.value; nil});
};

var bus =  Bus.audio(s, 2);
var rev = {Out.ar(0, FreeVerb.ar(In.ar(bus, 2), mix: 0.3, room: 0.7, mul: 0.7))}.play;

/*
SynthDefs courtesy of Bruno Ruviaro:
"wow" and "pluck" two synth examples from 'A Gentle Introduction To SuperCollider'
https://ccrma.stanford.edu/~ruviaro/texts/A_Gentle_Introduction_To_SuperCollider.pdf

other synths from https://github.com/brunoruviaro/SynthDefs-for-Patterns licensed under GPL 3
additional credits: Mitchell Sigman (2011) Steal this Sound. Milwaukee, WI: Hal Leonard Books
Adapted for SuperCollider and elaborated by Nick Collins
http://www.sussex.ac.uk/Users/nc81/index.html
under GNU GPL 3 as per SuperCollider license
Minor modifications by Bruno Ruviaro, June 2015
*/

SynthDef("wow", {arg freq = 60, amp = 0.1, gate = 1, rel = 3, pan = 0, out = 0;
   var chorus, source, filtermod, env, snd;
   chorus = Lag.kr(freq, 2) * LFNoise2.kr([0.4, 0.5, 0.7, 1, 2, 5, 10]).range(1, 1.02);
   source = LFSaw.ar(chorus)*0.5;
   filtermod = SinOsc.kr(1/16).range(1, 10);
   env = Env.asr(1, amp, rel).kr(2, gate);
   snd = LPF.ar(in: source, freq: freq * filtermod, mul: env);
   Out.ar(out, Pan2.ar(snd, pan));
 }).add;

SynthDef("pluck", {arg amp = 0.1, freq = 440, decay = 5, mutedString = 0.1, pan = 0, out = 0;
  var env, snd;
  env = Env.linen(0, decay, 0).kr(doneAction: 2);
  snd = Pluck.ar(
    in: WhiteNoise.ar(amp),
    trig: Impulse.kr(0),
    maxdelaytime: 0.1,
    delaytime: freq.reciprocal,
    decaytime: decay,
    coef: mutedString
	);
	Out.ar(out, Pan2.ar(snd, pan));
}).add;

SynthDef("trianglewavebells",{
	arg out = 0, pan = 0.0, freq = 440, amp = 1.0, gate = 1, att = 0.01, dec = 0.1, sus = 1, rel = 0.5, lforate = 10, lfowidth = 0.0, cutoff = 100, rq = 0.5;
	var osc1, osc2, vibrato, filter, env;
	vibrato = SinOsc.ar(lforate, Rand(0, 2.0));
	osc1 = Saw.ar(freq * (1.0 + (lfowidth * vibrato)), 0.75);
	osc2 = Mix(LFTri.ar((freq.cpsmidi + [11.9, 12.1]).midicps));
	filter = RHPF.ar((osc1 + (osc2 * 0.5)) * 0.5, cutoff, rq);
	env = EnvGen.ar(
		envelope: Env.adsr(att, dec, sus, rel, amp),
		gate: gate,
		doneAction: 2);
	Out.ar(out, Pan2.ar(filter * env, pan));
}).add;

SynthDef("laserbeam", {
	arg out = 0, pan = 0.0, freq = 440, amp = 0.1, att = 0.01;
	var snd, freqenv, ampenv;
	// frequency envelope
	freqenv = EnvGen.ar(Env([4, 0.5, 1, 1], [att, 0.01, 1.0]));
	// amplitude envelope
	// no gate: fixed-time envelope, self-terminating.
	ampenv = EnvGen.ar(
		envelope: Env([0, 1, 0.5, 0.0], [0.02, 0.2, 0.1]),
		levelScale: amp,
		doneAction: 2);
	snd = LFTri.ar(freq: freq * freqenv, mul: ampenv);
	Out.ar(out, Pan2.ar(snd, pan));
}).add;

SynthDef("moogbass", {
	arg out = 0, pan = 0, freq = 440, amp = 0.1, gate = 1, cutoff = 1000, gain = 2.0, lagamount = 0.01, att = 0.001, dec = 0.3, sus = 0.9, rel = 0.2, chorus = 0.7;
	var osc, filter, env, filterenv, snd, chorusfx;
	osc = Mix(VarSaw.ar(
		freq: freq.lag(lagamount) * [1.0, 1.001, 2.0],
		iphase: Rand(0.0,1.0) ! 3,
		width: Rand(0.5,0.75) ! 3,
		mul: 0.5));
	filterenv = EnvGen.ar(
		envelope: Env.asr(0.2, 1, 0.2),
		gate: gate);
	filter =  MoogFF.ar(
		in: osc,
		freq: cutoff * (1.0 + (0.5 * filterenv)),
		gain: gain);
	env = EnvGen.ar(
		envelope: Env.adsr(0.001, 0.3, 0.9, 0.2, amp),
		gate: gate,
		doneAction: 2);
	snd = (0.7 * filter + (0.3 * filter.distort)) * env;
	chorusfx = Mix.fill(7, {
		var maxdelaytime = rrand(0.005, 0.02);
		DelayC.ar(
			in: snd,
			maxdelaytime: maxdelaytime,
			delaytime: LFNoise1.kr(
				freq: Rand(4.5, 10.5),
				mul: 0.25 * maxdelaytime,
				add: 0.75 * maxdelaytime)
		)
	});
	snd = snd + (chorusfx * chorus);
	Out.ar(out, Pan2.ar(snd, pan));
}).add;

tune_x = retune_all.value(0, offsets); // initialise by 'changing key' from C to C
reroll.value;   // first run
SystemClock.sched(0, {play_bar.value; nil});
)

