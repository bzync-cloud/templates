import gradio as gr


def greet(name: str) -> str:
    return f"Hello, {name or 'Bzync Cloud'}"


demo = gr.Interface(fn=greet, inputs="text", outputs="text", title="Gradio Starter")

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)
