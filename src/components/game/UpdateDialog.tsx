'use client';

import { useUpdater } from '@/lib/updater';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Loader2, Download, CheckCircle2, AlertCircle } from 'lucide-react';

export function UpdateDialog() {
  const { checking, updateAvailable, downloading, downloaded, error, version, notes, downloadAndInstall } = useUpdater();

  // Show nothing while checking (silent)
  if (checking) return null;

  // Show error dialog if updater failed (so user knows something is wrong)
  if (error && !updateAvailable) {
    return (
      <Dialog open={true}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertCircle className="h-5 w-5 text-amber-500" />
              Update check failed
            </DialogTitle>
            <DialogDescription className="pt-2">
              The auto-updater couldn't check for updates. You may need to download new versions manually from GitHub.
              <span className="block mt-2 text-xs text-red-500">{error}</span>
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end pt-2">
            <Button variant="ghost" onClick={() => window.dispatchEvent(new CustomEvent('update-dismissed'))}>
              Dismiss
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  // Show nothing if no update available or already downloaded
  if (!updateAvailable || downloaded) return null;

  return (
    <Dialog open={true}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Download className="h-5 w-5 text-emerald-500" />
            Update available — v{version}
          </DialogTitle>
          <DialogDescription className="pt-2">
            A new version of Unemployment Simulator is available.
            {notes && (
              <span className="block mt-2 text-xs whitespace-pre-line">{notes}</span>
            )}
          </DialogDescription>
        </DialogHeader>

        {error && (
          <div className="flex items-start gap-2 p-2 rounded-md bg-red-50 dark:bg-red-950/30 text-red-700 dark:text-red-400 text-xs">
            <AlertCircle className="h-4 w-4 mt-0.5 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <div className="flex justify-end gap-2 pt-2">
          <Button
            variant="ghost"
            onClick={() => {
              window.dispatchEvent(new CustomEvent('update-dismissed'));
            }}
            disabled={downloading}
          >
            Later
          </Button>
          <Button onClick={downloadAndInstall} disabled={downloading}>
            {downloading ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Downloading...
              </>
            ) : (
              <>
                <Download className="h-4 w-4 mr-2" />
                Download & Install
              </>
            )}
          </Button>
        </div>

        {downloaded && (
          <div className="flex items-center gap-2 p-2 rounded-md bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-400 text-xs">
            <CheckCircle2 className="h-4 w-4" />
            Download complete — the app will restart to install.
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
