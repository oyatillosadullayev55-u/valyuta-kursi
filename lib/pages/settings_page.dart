import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../utils/flags.dart';
import '../utils/format.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget section(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        t,
        style: tt.titleSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return ListView(
      children: [
        section('Ko\'rinish'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Tizim'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Yorug\''),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Tun'),
                ),
              ],
              selected: {c.themeMode},
              onSelectionChanged: (s) => c.setThemeMode(s.first),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < kAccents.length; i++)
                GestureDetector(
                  onTap: () => c.setAccent(i),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kAccents[i],
                      shape: BoxShape.circle,
                      border: c.accent == i
                          ? Border.all(color: cs.onSurface, width: 3)
                          : null,
                    ),
                    child: c.accent == i
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        ),
        section('Narx signallari'),
        if (c.alerts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Signal yo'q. Valyuta sahifasida qo'shishingiz mumkin.",
              style: tt.bodySmall?.copyWith(color: cs.outline),
            ),
          )
        else
          for (final a in c.alerts.values)
            ListTile(
              leading: Text(flagOf(a.code), style: const TextStyle(fontSize: 26)),
              title: Text(
                "${a.code} ${a.above ? '≥' : '≤'} ${fmt(a.target)} so'm",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => c.removeAlert(a.code),
              ),
            ),
        section("Ma'lumotlar"),
        ListTile(
          leading: const Icon(Icons.account_balance_outlined),
          title: const Text('Manba'),
          subtitle: const Text("O'zbekiston Respublikasi Markaziy banki (cbu.uz)"),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Oxirgi yangilanish'),
          subtitle: Text(
            c.updatedAt == null ? "Noma'lum" : fmtDateTime(c.updatedAt!),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined),
          title: const Text('Keshni tozalash'),
          subtitle: const Text("Saqlangan kurslar va grafiklar o'chiriladi"),
          onTap: () async {
            await c.clearCache();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kesh tozalandi')),
            );
          },
        ),
        section('Ilova haqida'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Valyuta kursi'),
          subtitle: Text('Versiya 3.0'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}