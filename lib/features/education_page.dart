part of '../main.dart';

extension _EducationPage on _ShionHomeState {
  Widget _education() {
    final matches = articles
        .where(
          (a) => ('${a.title} ${a.category}').toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return _scroll([
      TextFormField(
        initialValue: _query,
        decoration: const InputDecoration(
          hintText: 'Cari artikel...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (x) => _refresh(() => _query = x),
      ),
      const SizedBox(height: 15),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Semua', 'Daur Ulang', 'Tips', 'Gaya Hidup']
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c, style: const TextStyle(fontSize: 11)),
                    selected: _query == (c == 'Semua' ? '' : c),
                    onSelected: (_) =>
                        _refresh(() => _query = c == 'Semua' ? '' : c),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 17),
      if (matches.isEmpty)
        const Padding(
          padding: EdgeInsets.all(25),
          child: Text('Artikel belum ditemukan.'),
        ),
      for (int i = 0; i < matches.length; i++) ...[
        _articleCard(matches[i], large: i == 0),
        const SizedBox(height: 14),
      ],
    ]);
  }

  Widget _articleCard(Article a, {bool large = false}) => Glass(
    padding: EdgeInsets.zero,
    onTap: () => _page(
      'Edukasi',
      (_) => _scroll([
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(height: 245, child: RemotePhoto(a.photo)),
        ),
        const SizedBox(height: 22),
        serif(a.title, size: 30),
        const SizedBox(height: 14),
        Text(a.category, style: const TextStyle(color: sage, fontSize: 12)),
        const SizedBox(height: 20),
        Text(
          a.body,
          style: const TextStyle(height: 1.85, color: ink, fontSize: 15),
        ),
      ]),
    ),
    child: large
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 170,
                width: double.infinity,
                child: RemotePhoto(a.photo),
              ),
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    serif(a.title, size: 23),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          a.category,
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward, color: sage, size: 19),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        : Row(
            children: [
              SizedBox(width: 95, height: 108, child: RemotePhoto(a.photo)),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: const TextStyle(height: 1.4, fontSize: 13),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        a.category,
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}
