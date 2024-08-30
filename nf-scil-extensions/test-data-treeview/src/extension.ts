"use strict";

import * as vscode from "vscode";

import { TestDataProvider } from "./nfscilTestData";

export function activate(context: vscode.ExtensionContext) {
    const rootPath =
        vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders.length > 0
            ? vscode.workspace.workspaceFolders[0].uri.fsPath
            : undefined;

    const storagePath = context.globalStorageUri.fsPath;

    const testDataProvider = new TestDataProvider(rootPath, storagePath);

    vscode.window.registerTreeDataProvider("nfscilTestData", testDataProvider);

    vscode.commands.registerCommand("nfscilTestData.refreshEntry", () => testDataProvider.refresh());
    vscode.commands.registerCommand("nfscilTestData.clearCache", () => testDataProvider.clear(false));
    vscode.commands.registerCommand("nfscilTestData.loadListing", () => {
        vscode.window
            .showOpenDialog({
                canSelectFiles: true,
                canSelectFolders: false,
                canSelectMany: false,
                openLabel: "Load package listing",
                filters: {
                    "JSON files": ["json"],
                },
                defaultUri: rootPath ? vscode.Uri.file(rootPath) : undefined,
            })
            .then((uri) => {
                if (uri && uri[0]) {
                    testDataProvider.loadListing(uri[0].fsPath);
                } else {
                    vscode.window.showErrorMessage("No file selected");
                }
            });
    });
    vscode.commands.registerCommand("nfscilTestData.forceDownloadListing", () =>
        testDataProvider.forceDownloadListing(),
    );

    vscode.commands.registerCommand("nfscilTestData.openInEditor", (element) => testDataProvider.openInEditor(element));
    vscode.commands.registerCommand("nfscilTestData.saveAs", (element) => testDataProvider.saveAs(element));
}
