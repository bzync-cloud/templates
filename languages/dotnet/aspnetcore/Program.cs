var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => Results.Json(new { message = "ASP.NET Core API running on Bzync Cloud" }));
app.MapGet("/health", () => Results.Json(new { status = "ok" }));

app.Run();
