export async function load({ fetch }) {
  const apiUrl = process.env.API_URL || "http://backend:8000";
  const res = await fetch(`${apiUrl}/health`);
  return { status: (await res.json()).status };
}
