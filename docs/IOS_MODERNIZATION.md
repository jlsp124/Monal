# Monal iOS integration build

Repository: <https://github.com/jlsp124/Monal>  
Codemagic branch: `feature/monal-ios-modernization`  
Workflow: **Monal Alpha - unsigned iPhone IPA** (`monal-ios-unsigned`).

This branch extends Monal's native SwiftUI/UIKit chat. It preserves the existing XMPP connection, OMEMO, receipt, upload, history and extension infrastructure. It does not add a new app or web UI.

## Investigation and component map

The integration began at `694046104ab7c86d74f307a191d3622741f9fffa`, retaining `745ddd3564fb2f557e594a92261798a8798b0084` and the two existing Codemagic commits. Upstream `develop` was checked at `ac4a74a3e9fba494704922856da98c6064fafa54`.

Monal already had XEP-0444 reactions, receipt tracking, file uploads, static locations, SwiftUI settings and a substantial ExyteChat integration. ExyteChat already provided quote previews, contextual menus, native row swipe actions, audio capture/playback, waveform drawing and a system Photos picker backend. These implementations are reused.

The existing Monal ExyteChat fork is included in `Packages/ExyteChat`, with its MIT license and provenance in `UPSTREAM.md`, based on `monal-im/ExyteChat` commit `9fa1fd204c68de0cbd090bd35a18de17b4ef29ce`. Xcode uses that local package so the user builds one repository and branch. Its existing dependencies are retained; no new package was introduced. The untouched snapshot has its own commit, separate from the component modifications.

Related upstream work checked includes [location support #1732](https://github.com/monal-im/Monal/pull/1732), [upload/compression work #1750](https://github.com/monal-im/Monal/pull/1750), [thumbnail work #1568](https://github.com/monal-im/Monal/pull/1568), [the loose-ends roadmap #1495](https://github.com/monal-im/Monal/issues/1495), and the [iOS 27 last-message report #1722](https://github.com/monal-im/Monal/issues/1722). The code at the pinned base, rather than a PR description, determined what was already present. Existing upload compression, location and media processing are extended rather than replaced. The old UIKit chat has not been redesigned.

## Launch failure and build foundation

The supplied **2026-11-11 Monal.alpha** crash has `EXC_CRASH / SIGABRT`. Its main-thread stack reaches `getContainerURLForPathComponents:` from `configureLogging` and `initSystem`. That method asserted when the shared App Group container was unavailable. The report also lists a successfully loaded `Monal.alpha.debug.dylib`; it does not establish a missing debug library as the cause.

AltServer changes App Group identifiers and writes the authorized groups into each signed bundle's `ALTAppGroups` metadata. This contract was checked against [AltServer-Windows source](https://github.com/rileytestut/AltServer-Windows/blob/41fb42bc78056f59e64566f7561ba405ef59b5d9/AltServer/AltServerApp.cpp). The independent resolver tries Monal's original group first, then only matching `original.TEAM` candidates that the operating system actually authorizes. Logging, shared preferences, background transfers and reset all use the same resolved group. There is no separate private-container database fallback.

`CFBundleName` and `CFBundleDisplayName` are **Monal Alpha** in source. The executable remains **Monal.alpha**. The scripts do not rename executables or patch a compiled IPA. `ENABLE_DEBUG_DYLIB=NO` produces a conventional testing executable, and validation rejects an unexpected debug trampoline.

`codemagic.yaml` fetches submodules, runs the checked-in Rust bridge generator, installs Pods, builds the workspace's **Monal Alpha / Alpha** scheme and packages the complete application using `ditto`. Package validation checks platform, executable files, embedded framework/extension executables, extension bundle identifiers, device architecture and the Monal framework. Both app extensions remain included. A fresh staging directory prevents stale Payload files being included.

The resulting IPA is **unsigned**. AltServer or another compatible signer must sign the app, frameworks and extensions and provision matching App Groups/keychain capabilities. The resolver cannot grant a capability missing from a provisioning profile. App Group availability, keychain access, share-extension behavior, notifications/APNs and background delivery still require the signed iPhone build. Push capability and production push service compatibility are not established by a successful sideload.

## Backlog coverage

“Implemented” below describes the source change. Available automated checks and the remaining phone checks are reported separately; it does not mean every behavior was exercised with live accounts.

| Area | Implementation | Remaining acceptance |
| --- | --- | --- |
| A — Scrolling/keyboard | Reviewed send batching; flush pending incoming messages before local sends. Disable Exyte's premature composer scroll in Monal; reveal the persisted/uploaded message by ID. Preserve the inverted table's visual position on keyboard/composer resizing. Keep older-message insertion anchored, honor manual dragging, use adjusted insets for the latest position, and respect Reduce Motion. | Real iOS 27 keyboards, interactive dismissal, long histories, burst traffic, slow uploads and device performance. |
| B — Recording | Explicit tap-to-start, Stop, preview, Send and Discard using existing Apple audio infrastructure. Generation guards cover permission/cancellation races. Cancellation deletes the file; chat closure, backgrounding and interruption discard capture. Metering uses actual microphone power at 10 Hz; waveform storage is bounded to the most recent 60 seconds and duration remains cumulative. | Physical microphone, permission denial/re-enable, call interruptions, audio routing and long recordings. |
| C — Gestures/reactions | Native Exyte/UIKit row swipe actions and existing contextual menus. Left is the default; Settings → General → User Interface → Input offers Left/Right/Both/Disabled. Existing XEP-0444 add/change/remove handling is retained; grouped emoji counts show whether the current user reacted and can toggle that reaction. | Gesture feel, VoiceOver, group permissions and multi-client synchronization. |
| D — Rich replies | XEP-0461 references, additive reply metadata table, XEP-0428 scalar-counted quoted-text fallback for text messages, local previews and navigation to an already loaded original. Attachments and geo bodies remain valid URLs/URIs. Unknown originals retain fallback text. Quote colors are sanitized while preserving links and emphasis. Cancel Reply is an accessible button. | Interoperability with other clients, archived originals and OMEMO/group reply flows. |
| E — Composer/attachments | Existing multiline composer capped at six visible lines. Native attachment Menu, system Photos picker, file preview/removal and explicit Send. Image Paste uses Apple's user-initiated native Paste control in the attachment menu, without polling the clipboard. Owned temporary pasted files are cleaned up. | Photos/camera permissions, clipboard prompts, large screenshots, external Files providers and iOS 27 safe areas. |
| F — Emoji | One bubble policy for all short emoji messages; larger text for 1–3 Unicode graphemes. Families, skin tones, flags, keycaps and variation selectors are handled consistently. Explicit text-presentation selectors and ordinary digits remain text. | Device fonts, custom text size and mixed-script examples. |
| G — Connection/status | Account-state banner sizes naturally and disappears at a bound XMPP session. Queued, sending, server-sent, delivered, read and failed remain distinct. Retry clears old failure state and resets an unreceived message to pending; successful send acknowledgment clears stale errors. Receipt confirmation remains required for delivered. Manual Retry is retained. | Airplane mode, real reconnects, server rejections, lost receipts and automatic stream resumption. |
| H — Haptics | Subtle reply/reaction/recording feedback, controlled by Settings → General → User Interface → Input → Application haptics. Setting uses existing shared defaults and updates an open chat. | Physical vibration, persistence across launch and all supported device/system settings. |
| I — Polish | Native menus/pickers, grouped reactions, neutral readable quotes, rounded avatars, semantic secondary header text, larger controls and reduced-motion paths. Existing Monal theme and identity remain. | Visual review on the physical phone, larger Dynamic Type, dark mode and touch interactions. |

## Deliberate limits

- Reply navigation scrolls to an original already in the loaded conversation. It does not fetch arbitrary missing history automatically. The quote fallback remains visible when no original can be resolved.
- Rich replies are not offered for group messages missing the room-assigned stanza ID. XEP-0461 requires that ID. Editing an already rich-replied message is withheld in the menu for this testing iteration; ordinary message editing remains available.
- XEP-0461 is an Experimental XMPP extension. Protocol construction/parsing tests do not substitute for inter-client testing.
- Recording changes do not alter call handling or core XMPP reconnection logic. The meter shows recent input, not a synthetic animation.
- English strings were added for testing; new translations have not been commissioned.
- Account-dependent sending, OMEMO exchanges, receipt recovery, live uploads and notifications cannot be accepted without a test account/server and the physical signed installation. No production credentials were requested or added.
- The reply schema adds migration **7.014**. Its numbering must be reconciled with upstream's migration sequence before any future upstream contribution.

## Validation

The fork's `test.yml` manual dispatch accepts `tests`, `chat`, `launch` and `integration`. `integration` runs the existing Monal tests, isolated ExyteChat tests, device build/package validation, and a simulator build/install/cold-launch/relaunch check. The shared simulator helper initializes CoreSimulator, selects an available iPhone by UUID for the selected SDK, and installs a compatible Apple runtime if the runner lacks one. The selected runtime/device is recorded in `simulator.json`. Submodules stay at their committed revisions. Simulator launch monitoring checks survival for 20 seconds twice and saves screenshots/runtime logs. Tests do not run the Codemagic service itself; both systems use the same checked-in build/package scripts.

Baseline build/launch run: [43126691257](https://github.com/jlsp124/Monal/actions/runs/43126691257). Both SDK builds and unsigned package creation passed. The simulator showed Monal's onboarding screen and survived cold launch and relaunch. This baseline predates the remaining feature groups.

Combined feature validation and final exact-head results are recorded in the delivery report after the runs finish. Component tests lay out the real UITableView conversation and apply rapid updates. ImageRenderer captures the actual SwiftUI message components separately in light mode and dark mode with larger text; those images are not full application screenshots. A color-variation assertion rejects blank captures. The upstream application's UI test is skipped; that skip must not be reported as a passing end-to-end conversation test.

## iPhone acceptance checklist

1. Build the final integration branch in Codemagic; install the newly generated IPA with the same AltServer identity. Open, close and reopen Monal. If it exits, send the latest **Monal.alpha** analytics report; an audio-accessory `bug_type:305` report is unrelated.
2. Open an existing chat, read history, show/hide/change keyboards, type several lines, receive a burst, and use Latest messages. Send text, location and slow-upload attachments. Confirm order and that reading history is not interrupted.
3. Record, Stop, listen, Send and Discard. Test declining permission, canceling around permission approval, leaving the chat, backgrounding and an incoming call. Confirm real meter response and usable controls afterward.
4. Reply by left swipe and long press; switch direction, try Both/Disabled, cancel a quote, send it and tap its preview. Check quoted links in dark and light modes, a missing original, and a group message. Compare with another XMPP client.
5. Add/change/remove reactions from two clients. Confirm grouped counts and the own-reaction indicator update correctly.
6. Add Photos, camera, Files and a location; remove a file before sending. Copy a screenshot elsewhere and choose **Add attachment → Paste**. Confirm no clipboard access occurs merely by opening the chat.
7. Send standalone hearts, flags, skin tones, families and keycaps; compare 1–3 emoji with mixed text and four emoji.
8. Enable airplane mode and send; confirm Queued. Reconnect; confirm the banner clears and status progresses only with actual acknowledgments. Exercise a real failure and manual Retry; verify the failure clears after recovery without premature Delivered.
9. Toggle Application haptics, relaunch, and check reply/reaction/recording feedback. Repeat the key interactions with Reduce Motion, larger text, dark mode and VoiceOver. Check header, composer, quote and banner clipping.
10. Test the share extension, background receiving, notification permission and app reopening with an existing account. Check OMEMO identity/history remain usable. Report unsupported signing capabilities separately from UI defects.
