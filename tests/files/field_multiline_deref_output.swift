if true {
    let x = entry
        .objectWillChange
        .debounce(for: .seconds(1), scheduler: DispatchQueue.global(qos: .utility))
        .bind(self)
        .sink { [weak self] newEntries in self?.commitAll(entries: newEntries) }

}
