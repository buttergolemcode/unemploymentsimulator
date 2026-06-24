// Library entry point — separates the binary from the lib so we can reuse code
// in tests and (later) for the multiplayer server module.

use tauri_plugin_updater::UpdaterExt;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            // ====== AUTO-UPDATE CHECK FROM RUST SIDE ======
            // This runs BEFORE the frontend loads, so it works even if JS fails.
            // No dependency on window.__TAURI__ or dynamic imports.
            let handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                println!("[Updater] Starting update check from Rust...");

                let updater = match handle.updater() {
                    Ok(u) => u,
                    Err(e) => {
                        eprintln!("[Updater] Failed to get updater: {}", e);
                        return;
                    }
                };

                let update = match updater.check().await {
                    Ok(Some(update)) => {
                        println!("[Updater] Update available: v{}", update.version);
                        update
                    }
                    Ok(None) => {
                        println!("[Updater] No update available");
                        return;
                    }
                    Err(e) => {
                        eprintln!("[Updater] Update check failed: {}", e);
                        return;
                    }
                };

                // Show native dialog asking user to confirm
                let should_update = tauri_plugin_dialog::DialogExt::dialog(&handle)
                    .message(format!(
                        "A new version is available: v{}\n\n{}\n\nDo you want to download and install it now?",
                        update.version,
                        update.body.as_deref().unwrap_or("No release notes available.")
                    ))
                    .title("Update Available")
                    .kind(tauri_plugin_dialog::MessageDialogKind::Info)
                    .buttons(tauri_plugin_dialog::MessageDialogButtons::OkCancel)
                    .blocking_show();

                if !should_update {
                    println!("[Updater] User declined update");
                    return;
                }

                println!("[Updater] Downloading update...");
                match update.download_and_install(
                    |_a, _b| {},
                    || {},
                ).await {
                    Ok(()) => {
                        println!("[Updater] Update installed successfully");
                    }
                    Err(e) => {
                        eprintln!("[Updater] Failed to install update: {}", e);
                        tauri_plugin_dialog::DialogExt::dialog(&handle)
                            .message(format!("Failed to install update: {}\n\nYou can download it manually from GitHub.", e))
                            .title("Update Failed")
                            .kind(tauri_plugin_dialog::MessageDialogKind::Error)
                            .blocking_show();
                    }
                }
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
