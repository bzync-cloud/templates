import { LitElement, html } from "lit";
import { customElement } from "lit/decorators.js";

@customElement("my-app")
export class MyApp extends LitElement {
  render() {
    return html`
      <main>
        <h1>Vite Lit TypeScript</h1>
        <p>Deploying on Bzync Cloud.</p>
      </main>
    `;
  }
}
