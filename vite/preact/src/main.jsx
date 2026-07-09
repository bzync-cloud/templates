import { render } from "preact";

function App() {
  return (
    <main>
      <h1>Vite Preact</h1>
      <p>Deploying on Bzync Cloud.</p>
    </main>
  );
}

render(<App />, document.getElementById("app"));
