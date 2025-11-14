declare module "*.svg" {
  const content: string;
  export default content;
}

declare module "phoenix-colocated/has_a_website" {
    import { Hooks } from "phoenix_live_view";

    export const hooks: Hooks
}

declare module "phoenix" {
    export class Socket {
        constructor(endPoint: string, opts?: any);
        connect(): void;
        disconnect(callback?: () => void, code?: number, reason?: string): void;
        channel(topic: string, params?: object): Channel;
        onOpen(callback: () => void): void;
        onClose(callback: () => void): void;
        onError(callback: (error: any) => void): void;
        onMessage(callback: (msg: any) => void): void;
        isConnected(): boolean;
    }
}

interface LiveReloader {
    enableServerLogs: () => void;
    disableServerLogs: () => void;
    openEditorAtCaller: (targetNode: Node) => void;
    openEditorAtDef: (targetNode: Node) => void;
}

interface WindowEventMap {
    "phx:live_reload:attached": CustomEvent<LiveReloader>
}

interface Window {
    liveSocket: import("phoenix_live_view").LiveSocketInstanceInterface;
    liveReloader: LiveReloader
}