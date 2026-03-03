import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/notes_service.dart';
import 'note_form_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _service = NotesService();
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  NoteStatus? _statusFilter;
  NoteCategory? _categoryFilter;

  final _searchCtrl = TextEditingController();
  bool _isSearchMode = false;
  List<NoteModel>? _searchResults;
  bool _isSearching = false;
  Timer? _debounce;

  StreamSubscription<List<NoteModel>>? _streamSub;
  final List<NoteModel> _streamNotes = [];
  String? _streamError;
  bool _isStreamLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeStream();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _subscribeStream() {
    _streamSub?.cancel();
    setState(() {
      _streamError = null;
      _isStreamLoading = true;
    });

    _streamSub = _service
        .notesStream(
          uid: _uid,
          statusFilter: _statusFilter,
          categoryFilter: _categoryFilter,
        )
        .listen(
          (notes) {
            if (!mounted) return;
            setState(() {
              _streamNotes
                ..clear()
                ..addAll(notes);
              _isStreamLoading = false;
            });
          },
          onError: (e) {
            if (!mounted) return;
            setState(() {
              _streamError = e.toString();
              _isStreamLoading = false;
            });
          },
        );
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _isSearching = true);
    try {
      final results = await _service.searchByTitle(_uid, q);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  Future<void> _delete(NoteModel note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: Text('"${note.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteNote(_uid, note.id);
    }
  }

  void _applyFilter({NoteStatus? status, NoteCategory? category}) {
    setState(() {
      _statusFilter = status;
      _categoryFilter = category;
    });
    _subscribeStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск по заголовку...',
                  border: InputBorder.none,
                ),
              )
            : const Text('Заметки'),
        actions: [
          IconButton(
            icon: Icon(_isSearchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                _searchCtrl.clear();
                _searchResults = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_statusFilter != null || _categoryFilter != null)
            _FilterChips(
              status: _statusFilter,
              category: _categoryFilter,
              onClear: () => _applyFilter(),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearchMode) {
      if (_isSearching) return const Center(child: CircularProgressIndicator());
      if (_searchResults == null) {
        return const Center(child: Text('Введите запрос для поиска'));
      }
      if (_searchResults!.isEmpty) {
        return const Center(child: Text('Ничего не найдено'));
      }
      return ListView.builder(
        itemCount: _searchResults!.length,
        itemBuilder: (_, i) => _NoteCard(
          note: _searchResults![i],
          onEdit: () => _openForm(_searchResults![i]),
          onDelete: () => _delete(_searchResults![i]),
        ),
      );
    }

    if (_streamError != null) {
      return Center(child: Text('Ошибка: $_streamError'));
    }
    if (_isStreamLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_streamNotes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет заметок',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _streamNotes.length,
      itemBuilder: (_, i) => _NoteCard(
        note: _streamNotes[i],
        onEdit: () => _openForm(_streamNotes[i]),
        onDelete: () => _delete(_streamNotes[i]),
      ),
    );
  }

  Future<void> _openForm(NoteModel? note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormScreen(note: note)),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(
        currentStatus: _statusFilter,
        currentCategory: _categoryFilter,
        onApply: (status, category) {
          Navigator.pop(context);
          _applyFilter(status: status, category: category);
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor() {
    switch (note.status) {
      case NoteStatus.active:
        return Colors.blue;
      case NoteStatus.completed:
        return Colors.green;
      case NoteStatus.archived:
        return Colors.grey;
    }
  }

  String _categoryEmoji() {
    switch (note.category) {
      case NoteCategory.personal:
        return '👤';
      case NoteCategory.work:
        return '💼';
      case NoteCategory.study:
        return '📚';
      case NoteCategory.other:
        return '📌';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor().withValues(alpha: 0.15),
          child: Text(_categoryEmoji()),
        ),
        title: Text(
          note.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: note.status == NoteStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.content.isNotEmpty)
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: note.tags
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final NoteStatus? status;
  final NoteCategory? category;
  final VoidCallback onClear;
  const _FilterChips({this.status, this.category, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.deepPurple.withValues(alpha: 0.05),
      child: Row(
        children: [
          if (status != null)
            Chip(
              label: Text('Статус: ${status!.name}'),
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
            ),
          if (category != null) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text('Категория: ${category!.name}'),
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
            ),
          ],
          const Spacer(),
          TextButton(onPressed: onClear, child: const Text('Сбросить')),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final NoteStatus? currentStatus;
  final NoteCategory? currentCategory;
  final void Function(NoteStatus?, NoteCategory?) onApply;

  const _FilterSheet({
    this.currentStatus,
    this.currentCategory,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  NoteStatus? _status;
  NoteCategory? _category;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _category = widget.currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильтры',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Статус'),
          Wrap(
            spacing: 8,
            children: [
              _filterChip(
                'Все',
                _status == null,
                () => setState(() => _status = null),
              ),
              ...NoteStatus.values.map(
                (s) => _filterChip(
                  s.name,
                  _status == s,
                  () => setState(() => _status = s),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Категория'),
          Wrap(
            spacing: 8,
            children: [
              _filterChip(
                'Все',
                _category == null,
                () => setState(() => _category = null),
              ),
              ...NoteCategory.values.map(
                (c) => _filterChip(
                  c.name,
                  _category == c,
                  () => setState(() => _category = c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_status, _category),
              child: const Text('Применить'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
