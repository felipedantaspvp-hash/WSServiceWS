import { RefreshEvent } from 'lightning/refresh';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getFocusedTabInfo, refreshTab } from 'lightning/platformWorkspaceApi';

export async function refreshRecordPage(component, recordId, isConsoleNavigation) {
    await notifyRecordUpdateAvailable([{ recordId }]);
    component.dispatchEvent(new RefreshEvent());

    if (isConsoleNavigation !== true) {
        return;
    }

    try {
        const focusedTab = await getFocusedTabInfo();
        await refreshTab(focusedTab.tabId, { includeAllSubtabs: true });
    } catch {
        component.dispatchEvent(new RefreshEvent());
    }
}