this.pdfThumbnailViewer = new PDFThumbnailViewer({
    container: appConfig
        .sidebar
        .attachmentsView(111, subcall().wow())
        .more
        .some_method(111),
    eventBus,
    enableHWA,
});

