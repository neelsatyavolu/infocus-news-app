# InFocus — App Store and TestFlight

## App record (once, in App Store Connect; the API can't create apps)

| Field | Value |
|---|---|
| Platform | iOS |
| Name | InFocus (if taken: "InFocus News" or "InFocus – Paly") |
| Primary language | English (U.S.) |
| Bundle ID | com.infocuspaly.news |
| SKU | infocus-news-ios |

Then `scripts/release-ios.sh` uploads builds. Internal testers (team members) get them without review; external testers need Beta App Review.

## Listing

- **Subtitle:** Paly's student news, live
- **Category:** News · secondary Education
- **Support URL:** https://infocuspaly.com/support (also linked in the app: More → Help & support)
- **Marketing URL:** https://infocusnews.tv
- **Privacy Policy URL:** https://infocuspaly.com/privacy (also in the app: More → Privacy policy, and under the announcement form)
- **Keywords:** `paly,palo alto,high school,student,news,broadcast,infocus,announcements,sports,livestream,school`

**Promotional text**

> Watch the newest InFocus News episode, catch Paly games live, and get your announcement on the show.

**Description**

> InFocus is Palo Alto High School's student broadcast network. The app puts everything in one place:
>
> • Every InFocus News episode, season by season, with the announcements read on each show
> • The latest stories from infocusnews.tv: news, features, commentary and more
> • Livestreams of games, concerts and ceremonies, plus replays
> • Alerts when a new show is up, a story is posted, or InFocus goes live
> • Send an announcement for the show right from your phone
> • Save stories to watch later, and search by headline or reporter
>
> Made by students in Paly's broadcast journalism program.

**Screenshots:** 6 each for 6.9" iPhone (1320 × 2868) and 13" iPad (2064 × 2752), in `build/appstore-screenshots/{iphone,ipad}/` (not committed): Home with the announcements recap, Shows, a show with its announcements, Stories, Live, and the announcement form. Captured from the real app with live public InFocus content, status bar set to 9:41, mixed light and dark. Staff photos are left out of the store set.

## App Privacy answers

- **Tracking:** No. No analytics, ads or third-party SDKs.
- **Identifiers → Device ID:** the APNs push token, sent to the InFocus Portal with the chosen alert types. App Functionality. Not linked to the user. Not used for tracking.
- **Contact Info → Name, Email Address** and **User Content → Other User Content:** only when someone sends an announcement (name, email, announcement text), so producers can review it and follow up. App Functionality. Linked to the user (they typed their email). Not used for tracking.
- Saved stories and settings stay on the device.
- Videos play through YouTube's embedded player (youtube-nocookie.com).

## Age rating

None for every content question; it's a school news app. Unrestricted web access: No (stories open the website in Safari).

## Review notes

> InFocus is the official app of InFocus, Palo Alto High School's student broadcast network. No account or sign-in is needed. Shows and livestreams are the network's own YouTube videos, played with YouTube's embedded player; stories come from the network's website, infocusnews.tv.
>
> More → Submit an announcement sends an announcement request to the InFocus producers (it is reviewed before anything airs). Notifications are optional and only announce new shows, stories and livestreams.

## Export compliance

Only HTTPS through iOS: `ITSAppUsesNonExemptEncryption = false` in Info.plist, so no question per build.

## TestFlight "What to test"

> Open a show from Home or Shows and play it; check the announcements under it. Open a few stories (some play a video, some show a photo), save one, then find it under More → Saved stories. Search for a reporter's name in Stories. Turn notifications on from the welcome screen or Settings and leave the app closed for a while: you should get alerts for new shows and stories. Try Light and Dark in Settings. Send a test announcement only if you mean it — producers see it.
