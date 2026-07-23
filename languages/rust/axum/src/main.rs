use axum::{routing::get, Json, Router};
use serde::Serialize;
use std::{env, net::SocketAddr};

#[derive(Serialize)]
struct Message<'a> {
    message: &'a str,
}

#[derive(Serialize)]
struct Status<'a> {
    status: &'a str,
}

#[tokio::main]
async fn main() {
    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr: SocketAddr = format!("0.0.0.0:{port}").parse().expect("valid listen address");

    let app = Router::new()
        .route("/", get(|| async { Json(Message { message: "Axum API running on Bzync Cloud" }) }))
        .route("/health", get(|| async { Json(Status { status: "ok" }) }));

    let listener = tokio::net::TcpListener::bind(addr).await.expect("bind listener");
    axum::serve(listener, app).await.expect("run server");
}
