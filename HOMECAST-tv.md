# Google TV text screen - plan for the next build (user, 20-Oct-2026: "keep it .md, we'll add it next time")

## Now (staff widget w314, live on "next")
HomeCast sends the announcement to the TV's Default Media Receiver: title + subtitle + a 1280x720 text picture (`banner()`), with the
faculty photo (96 px, from FacPhoto, matched by name in the text). Switch `hc_tv` on widget page 4 (default on).

## What the user's TV showed (photo 20-Oct, 9:25 pm) - problems
- The picture is shown as a small card on the right (~half size) + a blurred copy as the full background -> text far too small from the sofa.
- Long messages cut ("what you've ..."); title cut ("Today's..."); the same words 4 times; "Default Media Receiver" label on screen.
- Colour looked orange instead of the dark brown 0xFF3B2A08 (TV tint or receiver processing).

## Step 1 - quick fix (next build, widget only)
Show only the first 1-2 sentences (about 120 characters) in very large letters (about 110-130 px on the 1280x720 picture), faculty photo
large (the stored photo is 96 px: ask the server for a bigger one if it exists). Short title (first ~40 characters), no repeated subtitle.
The full text is still spoken. No new setup.

## Step 2 - proper fix (later): own Cast receiver page
Full-screen custom page: big headline, photo, time, news-ticker style scrolling line, no "Default Media Receiver" label.
- User registers a Google Cast developer account once (about $5) and adds a "Custom Receiver" with the page URL -> gets an App ID.
- Page hosted in this repo (GitHub Pages / raw), a `urn:x-cast:com.davan.tv` message {title, text, photoUrl, secs}.
- Widget: LAUNCH that App ID instead of CC1AD845 (`HomeCast.APP`), send the message, keep playing the voice via the media namespace.
- Fallback: if the custom app fails to launch, use the Default Media Receiver as now.
