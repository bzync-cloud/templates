import React from "react";
import { createRoot } from "react-dom/client";

const apiUrl = import.meta.env.VITE_API_URL || "/api";

function App() {
  return (
    <main>
      <h1>Rails React Portal</h1>
      <p>API endpoint: {apiUrl}</p>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
