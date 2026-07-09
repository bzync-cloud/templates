use actix_web::{get, web, App, HttpServer, Responder};
use serde::Serialize;
use std::env;

#[derive(Serialize)]
struct Message<'a> {
    message: &'a str,
}

#[derive(Serialize)]
struct Status<'a> {
    status: &'a str,
}

#[get("/")]
async fn index() -> impl Responder {
    web::Json(Message { message: "Actix Web API running on Bzync Cloud" })
}

#[get("/health")]
async fn health() -> impl Responder {
    web::Json(Status { status: "ok" })
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{port}");

    HttpServer::new(|| App::new().service(index).service(health))
        .bind(addr)?
        .run()
        .await
}
