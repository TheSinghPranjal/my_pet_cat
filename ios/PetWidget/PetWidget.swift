import SwiftUI
import WidgetKit

// MARK: - Shared data

private enum Pen {
  static let ink = Color(red: 0x22 / 255, green: 0x36 / 255, blue: 0xB5 / 255)
  static let inkSoft = Color(red: 0x6E / 255, green: 0x86 / 255, blue: 0xDD / 255)
  static let pencil = Color(red: 0x26 / 255, green: 0x26 / 255, blue: 0x2B / 255)
  static let paper = Color(red: 0xFC / 255, green: 0xFB / 255, blue: 0xF6 / 255)
  static let coralLight = Color(red: 0xFB / 255, green: 0xD9 / 255, blue: 0xD2 / 255)
}

/// Must match AppLaunchRouter.widgetLink in Dart.
private let launchURL = URL(string: "mypetcat://game/home?source=widget")!

/// The payload the app writes when the player leaves the game (see
/// PetWidgetPayload in Dart). Missing or newer-schema data falls back to
/// defaults, so the widget always renders.
private struct PetPayload {
  static let appGroup = "group.com.thelazybearClub.myPetCat"
  static let schemaVersion = 1

  var pose = "idle"
  var lastInteraction: String?

  static func load() -> PetPayload {
    guard let defaults = UserDefaults(suiteName: appGroup),
          defaults.integer(forKey: "schemaVersion") <= schemaVersion
    else { return PetPayload() }
    return PetPayload(
      pose: defaults.string(forKey: "pose") ?? "idle",
      lastInteraction: defaults.string(forKey: "lastInteraction")
    )
  }
}

// MARK: - Timeline

struct PetEntry: TimelineEntry {
  let date: Date
  let pose: String
  let greeting: String
}

/// WidgetKit doesn't run the widget continuously, so the kitten "lives" through
/// pre-rendered poses on a relaxed timeline. iOS decides exactly when each
/// entry is shown.
struct PetProvider: TimelineProvider {
  private static let poses = [
    "idle", "look_at_toy", "paw_reach", "paw_tap", "happy", "tail_up", "blink", "rest", "tail_down",
  ]
  private static let defaultGreeting = "Come play with me!"

  func placeholder(in context: Context) -> PetEntry {
    PetEntry(date: Date(), pose: "idle", greeting: Self.defaultGreeting)
  }

  func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
    let payload = PetPayload.load()
    completion(PetEntry(date: Date(), pose: context.isPreview ? "idle" : payload.pose,
                        greeting: payload.lastInteraction ?? Self.defaultGreeting))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
    let payload = PetPayload.load()
    let greeting = payload.lastInteraction ?? Self.defaultGreeting
    let now = Date()
    // About 6 hours of poses, 20 minutes apart, starting with the shared pose.
    let entries = (0..<18).map { i in
      PetEntry(
        date: now.addingTimeInterval(Double(i) * 20 * 60),
        pose: i == 0 ? payload.pose : Self.poses[i % Self.poses.count],
        greeting: greeting
      )
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

// MARK: - Views

private struct Kitten: View {
  let pose: String

  var body: some View {
    Image("widget_kitten_\(pose)")
      .resizable()
      .interpolation(.high)
      .scaledToFit()
      .id(pose)
      .transition(.opacity)
      .accessibilityHidden(true)
  }
}

private struct Title: View {
  let size: CGFloat

  var body: some View {
    Text("My Pet Cat")
      .font(.system(size: size, weight: .heavy, design: .rounded))
      .foregroundColor(Pen.ink)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
  }
}

private struct TapPill: View {
  let size: CGFloat

  var body: some View {
    Text("Tap to Play")
      .font(.system(size: size, weight: .heavy, design: .rounded))
      .foregroundColor(Pen.ink)
      .lineLimit(1)
      .padding(.horizontal, size)
      .padding(.vertical, size * 0.3)
      .background(Capsule().fill(Pen.coralLight))
      .overlay(Capsule().stroke(Pen.ink, lineWidth: 1.5))
  }
}

private struct Greeting: View {
  let text: String
  let size: CGFloat
  let lines: Int

  var body: some View {
    Text(text)
      .font(.system(size: size, weight: .medium, design: .rounded).italic())
      .foregroundColor(Pen.pencil)
      .multilineTextAlignment(.center)
      .lineLimit(lines)
      .minimumScaleFactor(0.8)
  }
}

struct PetWidgetView: View {
  let entry: PetEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    content
      .padding(family == .systemSmall ? 8 : 12)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(ContainerRelativeShape().inset(by: 3).strokeBorder(Pen.ink, lineWidth: 2.5))
      .widgetPaperBackground()
      .widgetURL(launchURL)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("My Pet Cat. \(entry.greeting) Tap to play.")
      .accessibilityAddTraits(.isButton)
  }

  @ViewBuilder private var content: some View {
    switch family {
    case .systemMedium:
      HStack(spacing: 6) {
        Kitten(pose: entry.pose).frame(maxWidth: .infinity)
        VStack(spacing: 5) {
          Title(size: 17)
          Greeting(text: entry.greeting, size: 13, lines: 2)
          Image("widget_food_bowl").resizable().scaledToFit().frame(height: 28).accessibilityHidden(true)
          TapPill(size: 12)
        }
        .frame(maxWidth: .infinity)
      }
    case .systemLarge:
      VStack(spacing: 6) {
        Title(size: 21)
        Greeting(text: entry.greeting, size: 14, lines: 1)
        ZStack(alignment: .bottom) {
          Image("widget_rug").resizable().scaledToFit().padding(.horizontal, 6).accessibilityHidden(true)
          Kitten(pose: entry.pose).padding(.horizontal, 12).padding(.bottom, 12)
          HStack {
            Image("widget_food_bowl").resizable().scaledToFit().frame(width: 56).accessibilityHidden(true)
            Spacer()
          }
        }
        .frame(maxHeight: .infinity)
        Text("Ready to play")
          .font(.system(size: 12, weight: .semibold, design: .rounded))
          .foregroundColor(Pen.inkSoft)
        TapPill(size: 14)
      }
    default:
      VStack(spacing: 2) {
        Title(size: 13)
        Kitten(pose: entry.pose).frame(maxHeight: .infinity)
        Text("Tap to play ▸")
          .font(.system(size: 10, weight: .semibold, design: .rounded))
          .foregroundColor(Pen.inkSoft)
          .lineLimit(1)
      }
    }
  }
}

private struct PaperBackground: View {
  var body: some View {
    ZStack {
      Pen.paper
      Image("widget_paper").resizable().scaledToFill()
    }
  }
}

extension View {
  /// iOS 17 requires widgets to declare their background this way.
  @ViewBuilder func widgetPaperBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { PaperBackground() }
    } else {
      background(PaperBackground())
    }
  }
}

// MARK: - Widget

struct PetWidget: Widget {
  let kind = "PetWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PetProvider()) { entry in
      PetWidgetView(entry: entry)
    }
    .configurationDisplayName("My Pet Cat")
    .description("Your kitten on your Home Screen. Tap to play.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .paperContentMargins()
  }
}

extension WidgetConfiguration {
  /// Our layout draws its own notebook margins.
  func paperContentMargins() -> some WidgetConfiguration {
    if #available(iOSApplicationExtension 17.0, *) {
      return contentMarginsDisabled()
    }
    return self
  }
}

@main
struct PetWidgetBundle: WidgetBundle {
  var body: some Widget {
    PetWidget()
  }
}
