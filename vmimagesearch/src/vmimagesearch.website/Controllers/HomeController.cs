using Microsoft.AspNet.Mvc;

namespace vmimagesearch.website.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
