import { Component } from "@angular/core";
import { bootstrapApplication } from "@angular/platform-browser";

@Component({
  selector: "app-root",
  standalone: true,
  template: "<h1>Angular app running on Bzync Cloud</h1>"
})
class AppComponent {}

bootstrapApplication(AppComponent).catch((err) => console.error(err));
