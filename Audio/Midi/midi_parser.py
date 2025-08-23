import mido
import json
import sys
import os

if len(sys.argv) < 2:
    print("Usage: python parse_midi.py <midi_file>")
    sys.exit(1)

midi_filename = sys.argv[1]
midi_file = mido.MidiFile(midi_filename)

# Defaults
current_tempo = 500000  # microseconds per beat (120 BPM)
current_ts = [4, 4]     # time signature numerator/denominator
ticks_per_beat = midi_file.ticks_per_beat

active_notes = {}
notes = []

# Keep track of maximum track time for total song duration
max_time = 0

for i, track in enumerate(midi_file.tracks):
    track_time = 0
    for msg in track:
        # Advance track time in seconds
        track_time += mido.tick2second(msg.time, ticks_per_beat, current_tempo)
        
        # Update tempo or time signature if changed
        if msg.type == 'set_tempo':
            current_tempo = msg.tempo
        elif msg.type == 'time_signature':
            current_ts = [msg.numerator, msg.denominator]
        
        # Start note
        elif msg.type == 'note_on' and msg.velocity > 0:
            active_notes[(msg.channel, msg.note)] = track_time
        
        # End note
        elif msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
            key = (msg.channel, msg.note)
            if key in active_notes:
                start_time = active_notes[key]
                duration = track_time - start_time
                notes.append({
                    "track": i,
                    "channel": msg.channel + 1,
                    "key": msg.note,
                    "start_time": start_time,
                    "end_time": track_time,
                    "duration": duration,
                    "hold": duration > 0.5,
                    "tempo": round(mido.tempo2bpm(current_tempo)),
                    "time_signature": current_ts.copy()
                })
                del active_notes[key]

    # Update max_time after each track
    if track_time > max_time:
        max_time = track_time

# Sort notes by start_time
notes.sort(key=lambda note: note['start_time'])

# Add total song duration to each note dictionary
for note in notes:
    note["song_duration"] = max_time

# Save JSON using MIDI filename as prefix
base_name = os.path.splitext(os.path.basename(midi_filename))[0]
with open(f"{base_name}_notes.json", "w") as f:
    json.dump(notes, f, indent=4)

print(f"Parsed '{midi_filename}' → {base_name}_notes.json")
