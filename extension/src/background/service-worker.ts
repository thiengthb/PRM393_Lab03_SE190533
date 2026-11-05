// The toolbar button (and Alt+Shift+F) opens the side panel. The worker holds no state and makes
// no network calls; everything else runs in the side panel page.
chrome.runtime.onInstalled.addListener(() => {
  void chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true });
});

chrome.runtime.onStartup.addListener(() => {
  void chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true });
});
