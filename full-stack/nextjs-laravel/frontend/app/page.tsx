export default async function Home() {
  const apiUrl = process.env.API_URL || "http://backend:8000";
  const res = await fetch(`${apiUrl}/health`, { cache: "no-store" });
  const data = await res.json();
  return <main><h1>Next.js + Laravel</h1><p>API status: {data.status}</p></main>;
}
