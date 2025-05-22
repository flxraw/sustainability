import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'About StreeAIability',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'An interactive platform that empowers citizens to reimagine and reshape the future of Munich\'s streets through sustainable urban design.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'Our Mission',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'StreeAIability is a collaborative initiative developed in partnership with MCube to create a sustainable, citizen-centered approach to urban planning in Munich. '
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
              'StreeAIability is more than just a design tool - it\'s a community platform that connects citizens\' ideas with urban planning expertise and policy implementation. '
              'By using our interactive design interface, you\'re contributing to a collective vision for Munich\'s future.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: _InfoCard(
                    title: 'How It Works',
                    content:
                        'Our platform allows you to upload images of your streets and add sustainable urban elements through a simple drag-and-drop interface. As you design, real-time impact scores show how your changes affect pollution levels and resident happiness.\n\n'
                        'The most popular designs are reviewed by our team of urban planners and shared with local decision-makers as part of our commitment to participatory urban development.',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _InfoCard(
                    title: 'The Technology',
                    content:
                        'StreeAIability uses AI technology to transform your street designs into realistic visualizations. Our scoring system is based on environmental impact research and urban livability studies.\n\n'
                        'All elements in our design palette are based on real-world sustainable urban solutions, many of which are already being tested or implemented in Munich and other forward-thinking cities.',
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
              'MCube is at the forefront of developing autonomous mobility solutions for urban environments. Their innovative approach to transportation is helping cities like Munich reduce emissions, '
              'decrease congestion, and create more people-friendly streets.\n\n'
              'Through our partnership, StreeAIability incorporates MCube\'s autonomous bus technology and mobility expertise into its design palette, allowing users to envision how these cutting-edge solutions could transform their streets.',
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
              'Contributors',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: const [
                ContributorCard(
                  name: 'Felix Hauger',
                  role: 'Masters student at TUM',
                  imagePath: 'assets/profiles/felix.png',
                  isAsset: true,
                  linkedInUrl: 'https://www.linkedin.com/in/felix-hauger/',
                ),
                ContributorCard(
                  name: 'Bela Goldbrunner',
                  role: 'Masters student at TUM',
                  imagePath: 'assets/profiles/bela.png',
                  isAsset: true,
                  linkedInUrl: 'https://www.linkedin.com/in/belagoldbrunner',
                ),
                ContributorCard(
                  name: 'Josefine Jacobs',
                  role: 'Masters student at TUM',
                  imagePath: 'assets/profiles/josefine.png',
                  isAsset: true,
                  linkedInUrl:
                      'https://www.linkedin.com/in/josefine-jacobs-85a270246/',
                ),
                ContributorCard(
                  name: 'Jacqueline Walk',
                  role: 'Student at Hochschule München',
                  imagePath: 'assets/profiles/jacqueline.png',
                  isAsset: true,
                  linkedInUrl: 'https://www.linkedin.com/in/jacqueline-walk/',
                ),
                ContributorCard(
                  name: 'Laila Yassin',
                  role: 'Student at Hochschule München',
                  imagePath: 'assets/profiles/laila.png',
                  isAsset: true,
                  linkedInUrl: 'https://www.linkedin.com/in/lailayassin/',
                ),
              ],
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
                    onPressed: () {},
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
        const Text("•  ", style: TextStyle(fontSize: 20)),
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
    this.isAsset = false,
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
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage:
                  isAsset
                      ? AssetImage(imagePath)
                      : NetworkImage(imagePath) as ImageProvider,
              radius: 36,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              role,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.link, size: 18, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
