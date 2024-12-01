//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import SwiftUI

struct WorkoutSection: View {
    let workouts: [HKWorkout]

    var body: some View {
        Section(header: Text("Workouts")) {
            if workouts.isEmpty {
                Text("No workouts found.")
            } else {
                ForEach(workouts, id: \.uuid) { workout in
                    VStack(alignment: .leading) {
                        Text("Type: \(workout.workoutActivityType)")
                        Text("Duration: \(workout.duration.formatted()) seconds")
                    }
                }
            }
        }
    }
}

struct SleepSection: View {
    let sleepAnalysis: [HKCategorySample]

    var body: some View {
        Section(header: Text("Sleep")) {
            if sleepAnalysis.isEmpty {
                Text("No sleep data found.")
            } else {
                ForEach(sleepAnalysis, id: \.uuid) { sleep in
                    VStack(alignment: .leading) {
                        Text("Start: \(sleep.startDate.formatted())")
                        Text("End: \(sleep.endDate.formatted())")
                    }
                }
            }
        }
    }
}

struct HealthMetricsView: View {
    @State private var stepCount: Double = 0
    @State private var dietaryProtein: Double = 0
    @State private var workouts: [HKWorkout] = []
    @State private var sleepAnalysis: [HKCategorySample] = []

    let healthStore = HKHealthStore()

    var body: some View {
        NavigationView {
            List {
                Text("Step Count: \(stepCount, specifier: "%.0f") steps")
                Text("Dietary Protein: \(dietaryProtein, specifier: "%.1f") g")
                
                WorkoutSection(workouts: workouts)
                SleepSection(sleepAnalysis: sleepAnalysis)
            }
            .navigationTitle("Health Metrics")
            .onAppear(perform: fetchHealthMetrics)
        }
    }

    private func fetchHealthMetrics() {
        fetchStepCount()
        fetchDietaryProtein()
        fetchWorkouts()
        fetchSleepAnalysis()
    }

    private func fetchStepCount() {
        let stepType = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: [])
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            DispatchQueue.main.async {
                stepCount = sum.doubleValue(for: HKUnit.count())
            }
        }
        healthStore.execute(query)
    }

    private func fetchDietaryProtein() {
        let proteinType = HKQuantityType(.dietaryProtein)
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: [])
        let query = HKStatisticsQuery(quantityType: proteinType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            DispatchQueue.main.async {
                dietaryProtein = sum.doubleValue(for: HKUnit.gram())
            }
        }
        healthStore.execute(query)
    }

    private func fetchWorkouts() {
        let workoutType = HKWorkoutType.workoutType()
        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 100, sortDescriptors: nil) { _, results, _ in
            guard let results = results as? [HKWorkout] else {
                return
            }
            DispatchQueue.main.async {
                workouts = results
            }
        }
        healthStore.execute(query)
    }

    private func fetchSleepAnalysis() {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: 100, sortDescriptors: nil) { _, results, _ in
            guard let results = results as? [HKCategorySample] else {
                return
            }
            DispatchQueue.main.async {
                sleepAnalysis = results
            }
        }
        healthStore.execute(query)
    }
}
