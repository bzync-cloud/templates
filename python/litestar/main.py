from litestar import Litestar, get


@get("/")
async def index() -> dict[str, str]:
    return {"message": "Litestar API running on Bzync Cloud"}


@get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


app = Litestar(route_handlers=[index, health])
