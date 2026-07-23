import { LitElement, html } from "lit";

class MyApp extends LitElement {
  render() {
    return html`
      <main>
        <h1>Vite Lit</h1>
        <p>Deploying on Bzync Cloud.</p>
      </main>
    `;
  }
}

customElements.define("my-app", MyApp);
