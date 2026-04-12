import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/vocab.dart';
import '../services/database_service.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final List<String> _categories = ['All', 'Basics', 'Transport', 'Needs', 'Support'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  late Future<List<Vocab>> _vocabsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _vocabsFuture = DatabaseService.instance.getVocabs();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Dictionary'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search words...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        _onCategorySelected(category);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Vocab Grid
          Expanded(
            child: FutureBuilder<List<Vocab>>(
              future: _vocabsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No words found.'));
                }

                // Filter data
                final allVocabs = snapshot.data!;
                final filteredVocabs = allVocabs.where((vocab) {
                  final matchesCategory = _selectedCategory == 'All' || vocab.category == _selectedCategory;
                  final matchesSearch = vocab.word.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredVocabs.isEmpty) {
                  return const Center(child: Text('No matching words.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredVocabs.length,
                  itemBuilder: (context, index) {
                    final vocab = filteredVocabs[index];
                    return InkWell(
                      onTap: () => _openVideoModal(context, vocab),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                vocab.word,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  vocab.category,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openVideoModal(BuildContext context, Vocab vocab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _VideoModal(vocab: vocab);
      },
    );
  }
}

class _VideoModal extends StatefulWidget {
  final Vocab vocab;

  const _VideoModal({required this.vocab});

  @override
  State<_VideoModal> createState() => _VideoModalState();
}

class _VideoModalState extends State<_VideoModal> {
  VideoPlayerController? _controller;
  bool _isError = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.vocab.videoPaths.isNotEmpty) {
      _loadVideo(_currentIndex);
    }
  }

  void _loadVideo(int index) {
    _controller?.dispose();
    setState(() {
      _isError = false;
      _controller = null; // trigger loading state
    });

    final newController = VideoPlayerController.asset(widget.vocab.videoPaths[index]);
    newController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _controller = newController;
        });
        _controller!.play();
        _controller!.setLooping(true);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    });
  }

  void _nextVideo() {
    if (_currentIndex < widget.vocab.videoPaths.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadVideo(_currentIndex);
    }
  }

  void _previousVideo() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadVideo(_currentIndex);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.vocab.word,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.vocab.category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isError || widget.vocab.videoPaths.isEmpty
                  ? const Center(
                      child: Text(
                        'Video missing\n(Add .mp4 to assets/videos/)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : _controller != null && _controller!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
            ),
          ),
          if (widget.vocab.videoPaths.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? _previousVideo : null,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Text(
                  'Video ${_currentIndex + 1} of ${widget.vocab.videoPaths.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  onPressed: _currentIndex < widget.vocab.videoPaths.length - 1 ? _nextVideo : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 24),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
