// Library entry point — completely self-contained auto-updater.
// Does NOT use tauri-plugin-updater. Instead does a plain HTTP GET to GitHub,
// compares versions, downloads the .exe, and runs the NSIS installer silently.

use serde::Deserialize;
use std::process::Command;

#[derive(Deserialize)]
struct UpdateManifest {
    version: String,
    notes: Option<String>,
    platforms: UpdatePlatforms,
}

#[derive(Deserialize)]
struct UpdatePlatforms {
    #[serde(rename = "windows-x86_64")]
    windows: UpdatePlatform,
}

#[derive(Deserialize)]
struct UpdatePlatform {
    url: String,
}

// Compare semantic version strings: returns true if `available` > `installed`
fn is_newer(available: &str, installed: &str) -> bool {
    let parse = |s: &str| -> Vec<u64> {
        s.trim_start_matches('v')
            .split('.')
            .filter_map(|p| p.split('-').next().and_then(|n| n.parse().ok()))
            .collect()
    };
    let a = parse(available);
    let b = parse(installed);
    for i in 0..a.len().max(b.len()) {
        let av = a.get(i).unwrap_or(&0);
        let bv = b.get(i).unwrap_or(&0);
        if av > bv { return true; }
        if av < bv { return false; }
    }
    false
}

// Show a native Windows MessageBox
#[cfg(windows)]
fn show_message_box(title: &str, body: &str, question: bool) -> bool {
    use std::ffi::CString;
    use std::os::raw::{c_int, c_uint};
    
    extern "system" {
        fn MessageBoxA(
            hWnd: *mut std::ffi::c_void,
            lpText: *const u8,
            lpCaption: *const u8,
            uType: c_uint,
        ) -> c_int;
    }
    
    let text = CString::new(body).unwrap();
    let caption = CString::new(title).unwrap();
    
    // MB_YESNO = 0x04, MB_OK = 0x00, MB_ICONQUESTION = 0x20, MB_ICONINFORMATION = 0x40
    let flags: c_uint = if question { 0x04 | 0x20 } else { 0x00 | 0x40 };
    
    let result = unsafe {
        MessageBoxA(
            std::ptr::null_mut(),
            text.as_ptr() as *const u8,
            caption.as_ptr() as *const u8,
            flags,
        )
    };
    
    // IDYES = 6
    result == 6
}

#[cfg(not(windows))]
fn show_message_box(title: &str, body: &str, question: bool) -> bool {
    println!("{}: {}", title, body);
    true
}

fn check_and_update(installed_version: &str) {
    println!("[Updater] Checking for updates (installed: {})...", installed_version);
    
    // Step 1: Fetch latest.json from GitHub
    let url = "https://github.com/buttergolemcode/unemploymentsimulator/releases/latest/download/latest.json";
    
    let response = match reqwest::blocking::get(url) {
        Ok(r) => r,
        Err(e) => {
            eprintln!("[Updater] Failed to fetch latest.json: {}", e);
            // Don't bother user with network errors — just skip
            return;
        }
    };
    
    let body = match response.text() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("[Updater] Failed to read response: {}", e);
            return;
        }
    };
    
    println!("[Updater] Got latest.json: {} bytes", body.len());
    
    let manifest: UpdateManifest = match serde_json::from_str(&body) {
        Ok(m) => m,
        Err(e) => {
            eprintln!("[Updater] Failed to parse JSON: {}", e);
            eprintln!("[Updater] JSON content: {}", &body[..body.len().min(500)]);
            return;
        }
    };
    
    println!("[Updater] Latest version: {}, Installed: {}", manifest.version, installed_version);
    
    // Step 2: Compare versions
    if !is_newer(&manifest.version, installed_version) {
        println!("[Updater] Already on latest version");
        return;
    }
    
    println!("[Updater] Update available: v{}", manifest.version);
    
    // Step 3: Ask user
    let notes = manifest.notes.as_deref().unwrap_or("No release notes.");
    let message = format!(
        "A new version is available: v{}\n\n{}\n\nDo you want to download and install it now?",
        manifest.version, notes
    );
    
    let confirmed = show_message_box("Update Available", &message, true);
    if !confirmed {
        println!("[Updater] User declined update");
        return;
    }
    
    // Step 4: Download the .exe
    println!("[Updater] Downloading from: {}", manifest.platforms.windows.url);
    show_message_box("Downloading", "Downloading update... Please wait.", false);
    
    let exe_response = match reqwest::blocking::get(&manifest.platforms.windows.url) {
        Ok(r) => r,
        Err(e) => {
            let msg = format!("Failed to download update: {}", e);
            show_message_box("Update Failed", &msg, false);
            return;
        }
    };
    
    let exe_bytes = match exe_response.bytes() {
        Ok(b) => b,
        Err(e) => {
            let msg = format!("Failed to read download: {}", e);
            show_message_box("Update Failed", &msg, false);
            return;
        }
    };
    
    println!("[Updater] Downloaded {} bytes", exe_bytes.len());
    
    // Step 5: Save to temp file
    let temp_dir = std::env::temp_dir();
    let temp_exe = temp_dir.join(format!("unemployment_sim_update_{}.exe", manifest.version));
    
    if let Err(e) = std::fs::write(&temp_exe, &exe_bytes) {
        let msg = format!("Failed to save update file: {}", e);
        show_message_box("Update Failed", &msg, false);
        return;
    }
    
    println!("[Updater] Saved to: {:?}", temp_exe);
    
    // Step 6: Run the NSIS installer silently (/S = silent, /D = install dir)
    // We spawn it and then exit the current app so the installer can replace files
    show_message_box("Installing", "The update will now install and restart the app.", false);
    
    let install_dir = std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|p| p.to_path_buf()))
        .unwrap_or_else(|| std::path::PathBuf::from("C:\\Program Files\\Unemployment Simulator"));
    
    println!("[Updater] Running installer silently to: {:?}", install_dir);
    
    // NSIS silent install: /S for silent, /D= for install directory
    match Command::new(&temp_exe)
        .arg("/S")
        .arg(format!("/D={}", install_dir.to_string_lossy()))
        .spawn()
    {
        Ok(_) => {
            println!("[Updater] Installer spawned successfully — exiting app");
            // Exit the current app so the installer can replace files
            std::process::exit(0);
        }
        Err(e) => {
            let msg = format!("Failed to start installer: {}\n\nThe update file was saved to:\n{:?}", e, temp_exe);
            show_message_box("Update Failed", &msg, false);
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // Get the current app version from tauri.conf.json (compiled in at build time)
    let current_version = env!("CARGO_PKG_VERSION");
    
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            // Run update check in a separate thread (blocking, but doesn't block the UI)
            let version = current_version.to_string();
            std::thread::spawn(move || {
                check_and_update(&version);
            });
            
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
