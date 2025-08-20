/// 
/// If it works it works
///
import gleam/erlang/process
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/list
import gleam/option
import gleam/result
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
    ["dolls", id] -> doll_page(req, id)

    // req parametresini geç
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

fn get_skin_param(req: wisp.Request) -> option.Option(String) {
  request.get_query(req)
  |> result.map(fn(params) {
    list.find_map(params, fn(param) {
      case param {
        #("skin", value) -> Ok(value)
        _ -> Error(Nil)
      }
    })
    |> option.from_result()
  })
  |> result.unwrap(option.None)
}

fn get_interaction_param(req: wisp.Request) -> Bool {
  let param_opt =
    request.get_query(req)
    |> result.map(fn(params) {
      list.find_map(params, fn(param) {
        case param {
          #("interaction", value) -> Ok(value)
          _ -> Error(Nil)
        }
      })
      |> option.from_result()
    })
    |> result.unwrap(option.None)

  case param_opt {
    option.Some("true") -> True
    _ -> False
  }
}

fn get_live2d_param(req: wisp.Request) -> Bool {
  let param_opt =
    request.get_query(req)
    |> result.map(fn(params) {
      list.find_map(params, fn(param) {
        case param {
          #("live2d", value) -> Ok(value)
          _ -> Error(Nil)
        }
      })
      |> option.from_result()
    })
    |> result.unwrap(option.None)

  case param_opt {
    option.Some("true") -> True
    _ -> False
  }
}

fn doll_page(req: wisp.Request, id: String) -> Response(wisp.Body) {
  let skin_id = get_skin_param(req)
  let interaction = get_interaction_param(req)
  let live2d = get_live2d_param(req)
  let doll_model = doll_page.init(id, skin_id, interaction, live2d)
  let content = doll_page.view(doll_model)
  let title = case doll_model.doll {
    option.Some(doll) -> "Doll " <> doll.name
    option.None -> "Doll " <> id
  }
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
