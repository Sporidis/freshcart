import 'package:flutter/material.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_state.dart';

class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({required this.step, super.key});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Row(
            children: List.generate(
              OnboardingStep.values.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: step.index == index ? 24 : 6,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: step.index == index
                      ? Colors.black
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Step ${step.index + 1} of ${OnboardingStep.values.length}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
