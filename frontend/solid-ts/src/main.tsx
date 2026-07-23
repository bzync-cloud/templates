import { render } from "solid-js/web";

function App() {
  return (
    <main>
      <h1>Vite Solid TypeScript</h1>
      <p>Deploying on Bzync Cloud.</p>
    </main>
  );
}

render(() => <App />, document.getElementById("app") as HTMLElement);
