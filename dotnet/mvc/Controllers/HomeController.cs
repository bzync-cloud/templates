using Microsoft.AspNetCore.Mvc;

namespace MvcStarter.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}
