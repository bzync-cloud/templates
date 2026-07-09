import reflex as rx


def index() -> rx.Component:
    return rx.container(rx.heading("Reflex app running on Bzync Cloud"))


app = rx.App()
app.add_page(index)
