import mido
import json
import os

# -------------------------------
# Folders
# -------------------------------

# Base directory of the script
base_dir = os.path.dirname(os.path.abspath(__file__))

# Folder containing MIDI files (create this and put your .mid files in it)
midi_folder = os.path.join(base_dir)

# Output folder for JSON files
output_folder = os.path.join(base_dir, "..", "Notes Data")
try:
    os.makedirs(output_folder, exist_ok=True)
except PermissionError:
    output_folder = os.path.join(os.path.expanduser("~"), "Documents", "MidiData")
    os.makedirs(output_folder, exist_ok=True)
    print(f"Could not access Data folder. Using fallback: {output_folder}")

print(f"MIDI folder: {midi_folder}")
print(f"Output folder: {output_folder}")

# -------------------------------
# Find MIDI files
# -------------------------------
if not os.path.exists(midi_folder):
    print("MIDI folder does not exist! Please create it and add .mid files.")
    exit()

midi_files = [f for f in os.listdir(midi_folder) if f.lower().endswith((".mid", ".midi"))]

if not midi_files:
    print("No MIDI files found in the MIDI folder.")
    exit()

print(f"Found {len(midi_files)} MIDI file(s): {midi_files}")

# -------------------------------
# Process each MIDI file
# -------------------------------
for midi_filename in midi_files:
    midi_path = os.path.join(midi_folder, midi_filename)
    midi_file = mido.MidiFile(midi_path)

    current_tempo = 500000  # microseconds per beat (120 BPM)
    current_ts = [4, 4]
    ticks_per_beat = midi_file.ticks_per_beat

    active_notes = {}
    notes = []

    for i, track in enumerate(midi_file.tracks):
        track_time = 0
        for msg in track:
            track_time += mido.tick2second(msg.time, ticks_per_beat, current_tempo)
            if msg.type == 'set_tempo':
                current_tempo = msg.tempo
            elif msg.type == 'time_signature':
                current_ts = [msg.numerator, msg.denominator]
            elif msg.type == 'note_on' and msg.velocity > 0:
                active_notes[(msg.channel, msg.note)] = track_time
            elif msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
                key = (msg.channel, msg.note)
                if key in active_notes:
                    start_time = active_notes[key]
                    duration = track_time - start_time
                    notes.append({
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

    notes.sort(key=lambda note: note['start_time'])

    # Save JSON
    base_name = os.path.splitext(midi_filename)[0]
    output_path = os.path.join(output_folder, f"{base_name}_notes.json")

    if os.path.exists(output_path):
        print(f"Skipped '{midi_filename}' → file already exists: {output_path}")
        continue

    with open(output_path, "w") as f:
        json.dump(notes, f, indent=4)

    print(f"Parsed '{midi_filename}' → {output_path}")

print("Done!")
