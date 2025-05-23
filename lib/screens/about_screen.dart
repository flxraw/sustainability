import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'felix.hauger@tum.de',
      query: Uri.encodeFull('subject=StreetAIability Inquiry'),
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridCount =
        screenWidth < 500
            ? 1
            : screenWidth < 900
            ? 2
            : 3;

    final creators = [
      const ContributorCard(
        name: 'Felix Hauger',
        role: 'Masters student at TUM',
        imagePath: 'assets/profiles/felix.jpg',
        isAsset: true,
        linkedInUrl: 'https://www.linkedin.com/in/felix-hauger/',
      ),
      const ContributorCard(
        name: 'Bela Goldbrunner',
        role: 'Masters student at TUM',
        imagePath: 'assets/profiles/bela.jpg',
        isAsset: true,
        linkedInUrl: 'https://www.linkedin.com/in/belagoldbrunner',
      ),
      const ContributorCard(
        name: 'Josefine Jacobs',
        role: 'Masters student at TUM',
        imagePath: 'assets/profiles/josefine.jpg',
        isAsset: true,
        linkedInUrl: 'https://www.linkedin.com/in/josefine-jacobs-85a270246/',
      ),
      const ContributorCard(
        name: 'Jacqueline Walk',
        role: 'Masters student at Hochschule München',
        imagePath: 'assets/profiles/jacqueline.jpg',
        isAsset: true,
        linkedInUrl: 'https://www.linkedin.com/in/jacqueline-walk/',
      ),
      const ContributorCard(
        name: 'Laila Yassin',
        role: 'Masters student at Hochschule München',
        imagePath: 'assets/profiles/laila.jpg',
        isAsset: true,
        linkedInUrl: 'https://www.linkedin.com/in/lailayassin/',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Back to Home',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.black,
              child: const Text(
                'About StreetAIability',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'An interactive platform that empowers citizens to reimagine and reshape the future of Munich streets through sustainable urban design.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'Our Mission',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'StreetAIability is a collaborative initiative developed in partnership with MCube to create a sustainable, citizen-centered approach to urban planning in Munich. '
              'We believe that the people who live in and move through our streets daily should have a voice in how those spaces evolve.\n\n'
              'Our platform bridges the gap between urban planning expertise and community knowledge, allowing citizens to visualize potential changes to their streets and understand their environmental and social impacts.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Goals',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  BulletPoint(
                    text: 'Empower citizens to participate in urban planning',
                  ),
                  BulletPoint(text: 'Promote sustainable mobility solutions'),
                  BulletPoint(
                    text: 'Increase green infrastructure in urban environments',
                  ),
                  BulletPoint(
                    text:
                        'Create safer, more accessible streets for all residents',
                  ),
                  BulletPoint(
                    text:
                        'Bridge the gap between innovative technology and practical implementation',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'About the Project',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'StreetAIability is more than just a design tool - it\'s a community platform that connects citizens\' ideas with urban planning expertise and policy implementation. '
              'By using our interactive design interface, you\'re contributing to a collective vision for Munich\'s future.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: const [
                SizedBox(
                  width: 400,
                  child: _InfoCard(
                    title: 'How It Works',
                    content:
                        'Upload street images and add sustainable elements using drag-and-drop. Real-time scores show the effect on happiness and pollution.\n\nTop designs are reviewed and presented to local decision-makers.',
                  ),
                ),
                SizedBox(
                  width: 400,
                  child: _InfoCard(
                    title: 'The Technology',
                    content:
                        'Uses AI to create realistic designs and calculate environmental impact. All elements are based on real urban interventions tested in Munich.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Our Partner: MCube',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'MCube is pioneering autonomous mobility in cities. Their tech helps reduce traffic, emissions, and noise while creating people-friendly spaces.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                const url = 'https://mcube-cluster.de/en/';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCEFF00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: const Text('Learn More About MCube'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Creators',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              itemCount: creators.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) => creators[index],
            ),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get Involved',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Have questions, suggestions, or want to collaborate with us? We\'d love to hear from you!',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Contact Us'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('•', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  const _InfoCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class ContributorCard extends StatelessWidget {
  final String name;
  final String role;
  final String imagePath;
  final bool isAsset;
  final String linkedInUrl;

  const ContributorCard({
    super.key,
    required this.name,
    required this.role,
    required this.imagePath,
    required this.isAsset,
    required this.linkedInUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => launchUrl(
            Uri.parse(linkedInUrl),
            mode: LaunchMode.externalApplication,
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[800],
              backgroundImage:
                  isAsset
                      ? AssetImage(imagePath)
                      : NetworkImage(imagePath) as ImageProvider,
              radius: 36,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              role,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
