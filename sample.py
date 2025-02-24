import outetts

# Configure the model
model_config = outetts.HFModelConfig_v2(
    model_path="OuteAI/OuteTTS-0.3-1B",
    tokenizer_path="OuteAI/OuteTTS-0.3-1B"
)
# Initialize the interface
interface = outetts.InterfaceHF(model_version="0.3", cfg=model_config)

# You can create a speaker profile for voice cloning, which is compatible across all backends.
# speaker = interface.create_speaker(audio_path="path/to/audio/file.wav")
# interface.save_speaker(speaker, "speaker.json")
# speaker = interface.load_speaker("speaker.json")

# Print available default speakers
interface.print_default_speakers()
# Load a default speaker
speaker = interface.load_default_speaker(name="en_male_1")

# Generate speech
gen_cfg = outetts.GenerationConfig(
    text="Speech synthesis is the artificial production of human speech.",
    temperature=0.1,
    repetition_penalty=1.1,
    max_length=4096,
    speaker=speaker,
    # voice_characteristics="upbeat enthusiasm, friendliness, clarity, professionalism, and trustworthiness"
)
output = interface.generate(config=gen_cfg)

# Save the generated speech to a file
output.save("output.wav")