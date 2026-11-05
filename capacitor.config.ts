import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.rizedijital.app',
  appName: 'RizeDijital',
  webDir: 'www',
  appendUserAgent: ' RizeDijitalNative/1.00.2',
  backgroundColor: '#ffffff',
  loggingBehavior: 'production',
  server: {
    url: 'https://www.rizedijital.com',
    cleartext: false,
    errorPath: 'offline.html'
  },
  android: {
    allowMixedContent: false,
    webContentsDebuggingEnabled: false,
    backgroundColor: '#ffffff'
  },
  ios: {
    handleApplicationNotifications: false,
    preferredContentMode: 'mobile',
    allowsLinkPreview: false,
    backgroundColor: '#ffffff'
  },
  plugins: {
    SystemBars: {
      insetsHandling: 'disable',
      style: 'DARK',
      hidden: false
    },
    SplashScreen: {
      launchShowDuration: 300,
      launchAutoHide: true,
      backgroundColor: '#ffffff',
      androidScaleType: 'CENTER_INSIDE',
      showSpinner: false
    }
  }
};

export default config;
