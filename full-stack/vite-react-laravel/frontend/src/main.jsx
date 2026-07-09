import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";

function App() {
  const [status, setStatus] = useState("loading");
  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_URL || "http://localhost:8000"}/health`)
      .then((res) => res.json())
      .then((data) => setStatus(data.status))
      .catch(() => setStatus("unavailable"));
  }, []);
  return <main><h1>Vite React + Laravel</h1><p>API status: {status}</p></main>;
}

createRoot(document.getElementById("root")).render(<App />);
