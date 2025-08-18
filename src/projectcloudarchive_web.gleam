/// 
/// If it works it works
///
import gleam/erlang/process
import gleam/http/response.{type Response}
import gleam/string_tree
import lustre/attribute as a
import lustre/element
import lustre/element/html
import mist
import wisp
import wisp/wisp_mist

import pages/about
import pages/dolls/id as doll_page
import pages/home
import pages/layout/footer
import pages/layout/header
import pages/list/dolls as dolls_list
import pages/not_found
import router.{type Route}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  process.sleep_forever()
}

// REQUEST HANDLER -------------------------------------------------------------

fn handle_request(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  case wisp.path_segments(req) {
    [] -> home_page()
    ["about"] -> about_page()
    ["list", "dolls"] -> dolls_list_page()
    ["dolls", id] -> doll_page(id)

    // 404
    _ -> not_found_page()
  }
}

// PAGE HANDLERS ---------------------------------------------------------------

fn home_page() -> Response(wisp.Body) {
  let #(home_model, _) = home.init(Nil)
  let content = home.view(home_model)
  render_page("Home", content, router.Index)
}

fn about_page() -> Response(wisp.Body) {
  let content = about.view()
  render_page("About", content, router.About)
}

fn dolls_list_page() -> Response(wisp.Body) {
  let model = dolls_list.init(Nil)
  let content = dolls_list.view(model)
  render_page("Dolls", content, router.AllDolls)
}

fn doll_page(id: String) -> Response(wisp.Body) {
  let doll_model = doll_page.init(id)
  let content = doll_page.view(doll_model)
  let title = "Doll: " <> id
  render_page(title, content, router.DollPage(id))
}

fn not_found_page() -> Response(wisp.Body) {
  let content = not_found.view_not_found()
  render_page("Not Found", content, router.NotFound)
}

fn render_page(
  title: String,
  content: element.Element(a),
  route: Route,
) -> Response(wisp.Body) {
  let html = build_html_page(title, content, route)
  let html_string = "<!DOCTYPE html>\n" <> element.to_string(html)
  wisp.html_response(string_tree.from_string(html_string), 200)
}

fn build_html_page(
  title: String,
  content: element.Element(a),
  route: Route,
) -> element.Element(a) {
  html.html([a.attribute("lang", "en")], [
    html.head([], [
      html.meta([a.attribute("charset", "UTF-8")]),
      html.meta([
        a.attribute("name", "viewport"),
        a.attribute("content", "width=device-width, initial-scale=1.0"),
      ]),
      html.link([
        a.href("../public/images/logo.png"),
      ]),
      html.title([], title <> " - Project Neural Cloud: Archive"),
      html.script([a.src("https://cdn.tailwindcss.com")], ""),
      html.meta([
        a.attribute("name", "description"),
        a.attribute("content", "Project Neural Cloud Archive - Dolls Archive"),
      ]),
    ]),
    html.body([a.class("bg-[#212121] min-h-screen")], [
      header.header_view(route),
      html.main([a.class("min-h-screen w-full bg-[#212121] pt-20")], [
        content,
      ]),
      footer.footer_view(route),
    ]),
  ])
}
