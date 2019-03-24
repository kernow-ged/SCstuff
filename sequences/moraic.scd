(
var base = 60;
var key = 0;

var current_note = base + (0..11).choose;

var long_beat = 0.5;

var short_beat = long_beat * 0.5;

var duration = long_beat;

var duration_atoms = [  // 2 per short_beat, 4 per long_beat
	[(short_beat / 6) * 2,  (short_beat / 6)],
	[(Rest(short_beat / 6) * 2),  (short_beat / 6)],
	[(short_beat / 6), (short_beat / 6), (short_beat / 6)],
	[(short_beat / 6), Rest(short_beat / 6), (short_beat / 6)],
	[(short_beat / 4),  (short_beat / 4)],
	[Rest(short_beat / 4),  (short_beat / 4)],
	[(short_beat / 4),  Rest(short_beat / 4)],
	[Rest(short_beat/2)]
];

var atom_freqs = [0.175, 0.1, 0.15, 0.15, 0.1, 0.1, 0.125, 0.1];
var atom_number_note_events = [2, 1, 3, 2, 2, 1, 1, 0];

var position = 1;
var chord = [0, 4, 7, 11];
var degrees = Scale.major.degrees;

var ii_transition_weights = [0.75, 0.15, 0.05, 0.05];   // => v | => dim | =>  |  v_bis  | => v_ter
var i_transition_weights = [0.2, 0.7, 0.1]; // VI, vi or ii
var dim_transition_weights = [0.75, 0.25]; // V7 | I^

var v_mode = 0; // in v, v_bis, v_ter

var i2vi = (transitions: [-3, 0, 3, 6], lands_on: [0, 3, 7, 10], scales: [Scale.aeolian.degrees], scale_weights: [1.0], position: 6, morae_weights: [0.25, 0.75]);

var i2vi_bis = (transitions: [-3, 0, 3, 6],
            	lands_on: [0, 4, 7, 10],
	            scales:[
		               Scale.whole.degrees,
		               Scale.mixolydian.degrees,
		               Scale.superLocrian.degrees,
		               Scale.majorPentatonic.degrees,
		               Scale.lydianMinor.degrees,
				       Scale.harmonicMinor.degrees,
	                   ],
	           scale_weights: [0.15, 0.23, 0.19, 0.15, 0.23, 0.05],
	           position: 6,
	           morae_weights: [0.25, 0.75]
               );

var i2ii = (transitions: [-1, -4, 2, 5], lands_on: [0, 3, 7, 10], scales: [Scale.dorian.degrees], scale_weights: [1.0], position: 2,  morae_weights: [0.25, 0.75]);

var vi2ii = (transitions: [-1, -4, 2, 5], lands_on: [0, 3, 7, 10], scales: [Scale.dorian.degrees], scale_weights: [1.0], position: 2,  morae_weights: [0.25, 0.75]);


var ii2v = (transitions: [-1, -4, 2, 5], lands_on: [0, 4, 7, 10],
	         scales:[
		            Scale.whole.degrees,
		            Scale.mixolydian.degrees,
		            Scale.superLocrian.degrees,
		            Scale.majorPentatonic.degrees,
		            Scale.lydianMinor.degrees,
				    Scale.harmonicMinor.degrees,
	                ],
	        scale_weights: [0.15, 0.23, 0.19, 0.15, 0.23, 0.05],
	        position: 5,
	        morae_weights: [0.25, 0.75]
            );


var ii2v_bis = (transitions: [-2, 1, 4, 7], lands_on: [0, 4, 7, 11],
	        scales:[Scale.major.degrees],
	        scale_weights: [1.0],
	        position: 5,
	        morae_weights: [0.25, 0.75]
            );

var ii2v_ter = (transitions: [-3, 3, 6], lands_on: [0, 3, 7, 10],
	        scales:[Scale.dorian.degrees],
	        scale_weights: [1.0],
	        position: 5,
	        morae_weights: [0.25, 0.75]
            );

var ii2dim = (transitions: [-3, 0, 3, 6], lands_on: [0, 3, 6, 10], scales: [Scale.diminished.degrees, Scale.locrian.degrees], scale_weights: [0.5, 0.5], position: 7,  morae_weights: [0.25, 0.75]);

var v2i = (transitions: [-1, -4, 2, 5], lands_on: [0, 4, 7, 11],
	        scales:[Scale.major.degrees],
	        scale_weights: [1.0],
	        position: 1,
	        morae_weights: [0.75, 0.25]
            );

var v2i_bis = (transitions: [-3, 0, 3, 6], lands_on: [0, 4, 7, 11],
	        scales:[Scale.major.degrees],
	        scale_weights: [1.0],
	        position: 1,
	        morae_weights: [0.75, 0.25]
            );

var v2i_ter = (transitions: [-2, 1, 4, 7], lands_on: [0, 4, 7, 11],
	        scales:[Scale.major.degrees],
	        scale_weights: [1.0],
	        position: 1,
	        morae_weights: [0.75, 0.25]
            );

var dim2v = (transitions: [-1, -4, 2, 5], lands_on: [0, 4, 7, 10],
	         scales:[
		            Scale.whole.degrees,
		            Scale.mixolydian.degrees,
		            Scale.superLocrian.degrees,
		            Scale.majorPentatonic.degrees,
		            Scale.lydianMinor.degrees,
				    Scale.harmonicMinor.degrees,
	                ],
	        scale_weights: [0.15, 0.23, 0.19, 0.15, 0.23, 0.05],
	        position: 5,
	        morae_weights: [0.25, 0.75]
            );


var dim2i = (transitions: [-2, 1, 4, 7], lands_on: [0, 4, 7, 11], scales: [Scale.major.degrees], scale_weights: [1.0], position: 1, morae_weights: [0.75, 0.25]);


var adjust_tempo = {
	arg tempo = 0.5;
	var l = tempo;
	var s = tempo * 0.5;
	if(duration == long_beat,
		{duration = l;},
		{duration = s;}
	);
	long_beat = l;
	short_beat = s;
	duration_atoms = [  // 2 per short_beat, 4 per long_beat
	   [(short_beat / 6) * 2,  (short_beat / 6)],
	   [(Rest(short_beat / 6) * 2),  (short_beat / 6)],
	   [(short_beat / 6), (short_beat / 6), (short_beat / 6)],
	   [(short_beat / 6), Rest(short_beat / 6), (short_beat / 6)],
	   [(short_beat / 4),  (short_beat / 4)],
	   [Rest(short_beat / 4),  (short_beat / 4)],
	   [(short_beat / 4),  Rest(short_beat / 4)],
	   [Rest(short_beat/2)]
     ];
};

var init = {
	arg tempo = 0.5, start_key = (0..11).choose, mode = [1,2].choose;
	position = mode;
	key = start_key;
	switch(position,
		1, {
			chord = [0, 4, 7 ,11];
			degrees = v2i.at(\scales).wchoose(v2i.at(\scale_weights));
			duration = [long_beat, short_beat].wchoose(v2i.at(\morae_weights));
		},
		2, {
			chord = [0, 3, 7, 10];
			degrees = vi2ii.at(\scales).wchoose(vi2ii.at(\scale_weights));
			duration = [long_beat, short_beat].wchoose(vi2ii.at(\morae_weights));
		}
	);
	chord = chord + base + key;
	adjust_tempo.value(tempo);
};

var next_chord = {
	switch(position,
		1, {switch([0,1,2].wchoose(i_transition_weights),
				0, {chord = i2vi.at(\lands_on);
					degrees = i2vi.at(\scales).wchoose(i2vi.at(\scale_weights));
					key = key + i2vi.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(i2vi.at(\morae_weights));
					position = 6;
				},
			    1, {chord = i2vi_bis.at(\lands_on);
					degrees = i2vi_bis.at(\scales).wchoose(i2vi_bis.at(\scale_weights));
					key = key + i2vi_bis.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(i2vi_bis.at(\morae_weights));
					position = 6;
				},
			    2, {chord = i2ii.at(\lands_on);
					degrees = i2ii.at(\scales).wchoose(i2ii.at(\scale_weights));
					key = key + i2ii.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(i2ii.at(\morae_weights));
					position = 2;
				}
			);
		},
		2, {switch([0,1,2,3].wchoose(ii_transition_weights),
			     0, {chord = ii2v.at(\lands_on);
					degrees = ii2v.at(\scales).wchoose(ii2v.at(\scale_weights));
					key = key + ii2v.at(\transitions).choose;
				    duration = [long_beat, short_beat].wchoose(ii2v.at(\morae_weights));
					key = key % 12;

					position = 5;
			     },
			     1, {chord = ii2dim.at(\lands_on);
					degrees = ii2dim.at(\scales).wchoose(ii2dim.at(\scale_weights));
					key = key + ii2dim.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(ii2dim.at(\morae_weights));
					position = 7;
		         },
				 2, {chord = ii2v_bis.at(\lands_on);
					degrees = ii2v_bis.at(\scales).wchoose(ii2v_bis.at(\scale_weights));
					key = key + ii2v_bis.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(ii2v_bis.at(\morae_weights));
					position = 5;
				    v_mode = 1;
			     },
				 3, {chord = ii2v_ter.at(\lands_on);
					degrees = ii2v_ter.at(\scales).wchoose(ii2v_ter.at(\scale_weights));
					key = key + ii2v_ter.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(ii2v_ter.at(\morae_weights));
					position = 5;
				    v_mode = 2;
		       	 }
	    	);
		},
		5, {switch(v_mode,
			     0, {chord = v2i.at(\lands_on);
					degrees = v2i.at(\scales).wchoose(v2i.at(\scale_weights));
					key = key + v2i.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(v2i.at(\morae_weights));
					position = 1;
			     },
			     1, {chord = v2i_bis.at(\lands_on);
					degrees = v2i_bis.at(\scales).wchoose(v2i_bis.at(\scale_weights));
					key = key + v2i_bis.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(v2i_bis.at(\morae_weights));
					position = 1;
				    v_mode = 0;
			     },
			     2, {chord = v2i_ter.at(\lands_on);
					degrees = v2i_ter.at(\scales).wchoose(v2i_ter.at(\scale_weights));
					key = key + v2i_ter.at(\transitions).choose;
					key = key % 12;
				    duration = [long_beat, short_beat].wchoose(v2i_ter.at(\morae_weights));
					position = 1;
				    v_mode = 0;
		       	 }
		    );
		},
		6, {chord = vi2ii.at(\lands_on);
			degrees = vi2ii.at(\scales).wchoose(vi2ii.at(\scale_weights));
			key = key + vi2ii.at(\transitions).choose;
			key = key % 12;
			duration = [long_beat, short_beat].wchoose(vi2ii.at(\morae_weights));
			position = 2;
		},
		7, {switch([0,1].wchoose(dim_transition_weights),
			     0, {chord = dim2v.at(\lands_on);
			         degrees = dim2v.at(\scales).wchoose(dim2v.at(\scale_weights));
			         key = key + dim2v.at(\transitions).choose;
			         key = key % 12;
				     duration = [long_beat, short_beat].wchoose(dim2v.at(\morae_weights));
			         position = 5;
			     },
			     1, {chord = dim2i.at(\lands_on);
			         degrees = dim2i.at(\scales).wchoose(dim2i.at(\scale_weights));
			         key = key + dim2i.at(\transitions).choose;
			         key = key % 12;
				     duration = [long_beat, short_beat].wchoose(dim2i.at(\morae_weights));
			         position = 1;
			     },
		    );
		}
	);
	chord = chord + base + key;
};


var nearest_tonic_and_degree = {
	arg degrees;
	var index_of_smallest = 0;
	var smallest = 12;
	var choices, distances;
	var nearest_tonic = (current_note - (current_note % 12)) + key;
	if( (nearest_tonic - current_note) > 6,
		{nearest_tonic = nearest_tonic - 12}
	);
	choices = [nearest_tonic, (nearest_tonic + degrees[2]), (nearest_tonic + degrees[4])];
	distances = [
		 (current_note - choices[0]).abs,
	     (current_note - choices[1]).abs,
	     (current_note - choices[2]).abs
	];
	distances.do( {
		arg item, index;
		if(item < smallest,
			{smallest = item;
			 index_of_smallest = index;
			}
		);
	});
	[nearest_tonic, choices[index_of_smallest], [0,2,4][index_of_smallest]];
	// ^ key center in octave nearest last note, the absolute midi note and the relative degree in scale
};



var gen_walk = {
	arg degrees, length = 2;
	var steps = [-3, -2, -1, 0, 1, 2, 3];
	var notes = [];
	var diff_array = [];
	var lower_bound = 48;
	var upper_bound = 84;
	var ntad = nearest_tonic_and_degree.value(degrees);
	var centre = ntad[0];
	var chosen_degree = ntad[2];
	current_note = ntad[1];
	notes = notes ++ current_note;
	(length - 1).do({diff_array = diff_array ++ steps.wchoose([0.1, 0.2, 0.15, 0.1, 0.15, 0.2, 0.1 ])});
	diff_array.do( {
		arg item, index;
		var new_note;
		if(current_note > upper_bound, {item = 0 - item.abs;}); // send downwards
		if(current_note < lower_bound, {item = item.abs;});	   // send upwards
		chosen_degree = chosen_degree + item;
		if(chosen_degree >= degrees.size,
			{chosen_degree = chosen_degree - degrees.size; degrees = degrees + 12;}
		);
		if(chosen_degree < 0,
			{chosen_degree = chosen_degree + degrees.size; degrees = degrees - 12;}
		);
		current_note = (centre + degrees[chosen_degree]);
		notes = notes ++ current_note;
	});
	notes;
};


var invert_chord = {
	switch([0,1,2].wchoose([0.15, 0.2, 0.65]),
		0, {chord[2] = chord[2] - 12; chord[3] = chord[3] - 12;},
		1, {chord[3] = chord[3] - 12;},
		2, {}
	);
};


var gen_seqlet = {
	var dur_seqlet = [];
	var note_seqlet = [];
	var no_atoms;
	var no_notes = 0;
	var note_index = 0;
	var i;
	var notes;
	if( duration == short_beat,
		{no_atoms = 2;},
		{no_atoms = 4;}
	);
	no_atoms.do( {
		i = (0..(duration_atoms.size-1)).wchoose(atom_freqs);
		dur_seqlet = dur_seqlet ++ duration_atoms[i];
		no_notes = no_notes + atom_number_note_events[i];
	});
	notes = gen_walk.value(degrees, no_notes);
	dur_seqlet.do( {
		arg item, index;
		if(item.isRest,
			{note_seqlet = note_seqlet ++ \rest;},
			{note_seqlet = note_seqlet ++ notes[note_index];
			 note_index = note_index + 1;
			}
		);
	});
	[note_seqlet, dur_seqlet];
};


var prep_chord = {
	var strum = 0.0;
	var chords, durations;
	if( duration == long_beat,
		{   strum = rand(0.04);
			chords = [chord]; // Pseq-ready
			durations = [duration];
		},
		{
			switch( [0,1].wchoose([0.75, 0.25]),
				0, {
					strum = rand(0.02);
					chords = [chord];
					durations = [duration];
				},
				1, {
					switch( [0,1].wchoose([0.75, 0.25]),
						0, {durations = [duration * 0.25, duration * 0.75];},
						1, {durations = [duration * 0.5, duration * 0.5];}
					);
					switch([0,1].wchoose([0.75, 0.25]),
						0, {chords = [ [chord[0]], [chord[1], chord[2], chord[3]]  ];},
						1, {chords = [ [chord[0], chord[1]], [chord[2], chord[3]]  ];}
					);
				}
			);
		}
	);
	[chords, durations, strum];
};


var gen_bass = {
	arg fund;
	var notes;
	var durations;
	if( duration == long_beat,
		{ durations = [duration * 0.5, duration * 0.5];
			notes = [fund, (fund + 12)];
		},
		{ durations = [duration];
		  notes = [fund];
		}
	);
	[notes, durations];
};


var gen_drums = {
	var bass, snare, hats;
	var b_s, h;
	var req;
	bass = [];
	snare = [];
	hats = [];
	if( duration == long_beat,
		{req = 2;},
		{req = 1;}
	);
	for( 1, req, {
		b_s = [
		       // bd      / sd
		      [[1,0,0,0],[0,0,1,0]],
		      [[1,0,0,0],[0,1,0,1]],
		      [[1,0,0,0],[0,0,1,1]],
		      [[1,1,0,0],[0,0,1,0]],
		      [[1,0,0,0],[0,1,1,1]],
		      [[1,0,0,0],[0,0,0,1]],
		      [[1,1,1,0],[0,0,0,1]],
		      [[1,0,1,0],[0,0,0,1]]
		].wchoose([0.22,0.16,0.16,0.16,0.1,0.08,0.06,0.06]);
		h = [
			[1,0,0,1,0,1],
			[1,0,1,1,0,1],
			[1,1,0,1,0,1],
			[1,1,1,1,0,1]
		].wchoose([0.5, 0.25, 0.17, 0.08]);
		for(0,3, {
			arg i;
			if( b_s[0][i] == 1,
				{bass = bass ++ (short_beat/4);},
				{bass = bass ++ Rest(short_beat/4);}
			);
			if( b_s[1][i] == 1,
				{snare = snare ++ (short_beat/4);},
				{snare = snare ++ Rest(short_beat/4);}
			);
		});
		for(0,5, {
			arg i;
			if( h[i] == 1,
				{hats = hats ++ (short_beat/6);},
				{hats = hats ++ Rest(short_beat/6);}
			);
		});
	});
	[bass, snare, hats];
};


var play_segment = {
	var bass = gen_bass.value(chord[0]);
	var a = invert_chord.value;
	var chords = prep_chord.value;
	var noodle = gen_seqlet.value;
	var drums = gen_drums.value;
	Pbind(
		\instrument, "blips1",
		\amp, 0.1,
		\legato, 0.99,
		\strum, chords[2],
		\midinote,  Pseq(chords[0], 1),
		\dur, Pseq(chords[1], 1),
		\pan, -0.8
	).play;
	Pbind(
		\instrument, "laserbeam",
		\amp, 0.2,
		\legato, 0.7,
		\midinote,  Pseq(noodle[0], 1),
		\dur, Pseq(noodle[1], 1),
		\pan, 0.7
	).play;
	Pbind(
		\instrument, "harpsichord1",
		\amp, 0.18,
		\legato, 0.6,
		\midinote, Pseq(bass[0]-24, 1),
		\dur, Pseq(bass[1], 1),
		\pan, -0.4
	).play;
	Pbind(
		\instrument, "kick",
		\dur, Pseq(drums[0], 1),
		\amp, 0.9,
		\rel, 0.12,
		\glissf, 0.99,
		\pan, -0.2
	).play;
	Pbind(
		\instrument, "snare",
		\dur, Pseq(drums[1], 1),
		\amp, 0.35,
		\rel, 0.1,
		\pan, 0.25
	).play;
	Pbind(
		\instrument, "hihat",
		\dur, Pseq(drums[2], 1),
		\ffreq, 6000,
		\att, 0.0,
		\rel, 0.05,
		\amp, 0.15,
		\pan, 0.3
	).play;
	SystemClock.sched(duration, {play_segment.value; nil});
	next_chord.value;
};

/*
SynthDefs courtesy of Bruno Ruviaro: https://github.com/brunoruviaro/SynthDefs-for-Patterns licensed under GPL 3
additional credits for "laserbeam":  Mitchell Sigman (2011) Steal this Sound. Milwaukee, WI: Hal Leonard Books
Adapted for SuperCollider and elaborated by Nick Collins
http://www.sussex.ac.uk/Users/nc81/index.html
under GNU GPL 3 as per SuperCollider license
Minor modifications by Bruno Ruviaro, June 2015.
*/

SynthDef("hihat", {arg out = 0, amp = 0.5, att = 0.01, rel = 0.2, ffreq = 6000, pan = 0;
	var snd = WhiteNoise.ar(amp);
	var env = Env.perc(att, rel).kr(doneAction: 2);
	snd = HPF.ar(snd * env, ffreq);
	Out.ar(out, Pan2.ar(snd, pan));
}).add;

SynthDef("snare", {arg out = 0, amp = 0.1, sinfreq = 180, att = 0.01, rel = 0.2, ffreq = 2000, pan = 0;
	var snd1 = WhiteNoise.ar(amp);
	var snd2 = SinOsc.ar(sinfreq,0,amp);
	var env = EnvGen.kr(Env.perc(att, rel), doneAction: 2);
	var sum = HPF.ar(snd1 * env, ffreq)+(snd2*env);
	Out.ar(out, Pan2.ar(sum, pan));
}).add;

SynthDef("kick", {arg out = 0, amp = 0.3, sinfreq = 60, glissf = 0.9, att = 0.01, rel = 0.45, pan = 0;
	var gliss = XLine.kr(sinfreq, sinfreq*glissf, rel);
	var snd = SinOsc.ar(gliss);
	var env = EnvGen.kr(Env.perc(att, rel), doneAction: 2);
	snd = snd * env * amp;
	Out.ar(out, Pan2.ar(snd, pan));
}).add;


SynthDef("harpsichord1", { arg out = 0, freq = 440, amp = 0.1, pan = 0;
    var env, snd;
	env = Env.perc(level: amp).kr(doneAction: 2);
	snd = Pulse.ar(freq, 0.25, 0.75);
	snd = snd * env;
	Out.ar(out, Pan2.ar(snd, pan));
}).add;

SynthDef("blips1", {arg out = 0, freq = 25, numharm = 12, att = 0.01, rel = 1.25, amp = 0.1, pan = 0;
	var snd, env;
	env = Env.perc(att, rel, amp).kr(doneAction: 2);
	snd = LeakDC.ar(Mix(Blip.ar([freq, freq*1.01], numharm, env)));
	Out.ar(out, Pan2.ar(snd, pan));
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

init.value(0.8);
SystemClock.sched(0, {play_segment.value; nil});  // start first segment off, then play_segment function loops indefinitely
)

