import React from "react";
import { createRoot } from "react-dom/client";

function App() {
  return (
    <main>
      <h1>Vite React</h1>
      <p>Deploying on Bzync Cloud.</p>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
