import { describe, it, expect, beforeEach } from "vitest"

describe("Resource Allocation Contract", () => {
  let mockStorage: Map<string, any>
  let resourceNonce: number
  
  beforeEach(() => {
    mockStorage = new Map()
    resourceNonce = 0
  })
  
  const mockContractCall = (method: string, args: any[], sender: string) => {
    switch (method) {
      case "add-resource":
        const [name, quantity] = args
        resourceNonce++
        mockStorage.set(`resource-${resourceNonce}`, {
          name,
          "total-quantity": quantity,
          "available-quantity": quantity,
        })
        return { success: true, value: resourceNonce }
      case "allocate-resource":
        const [missionId, resourceId, allocateQuantity] = args
        const resource = mockStorage.get(`resource-${resourceId}`)
        if (!resource) return { success: false, error: "Resource not found" }
        if (resource["available-quantity"] < allocateQuantity) {
          return { success: false, error: "Insufficient resources" }
        }
        resource["available-quantity"] -= allocateQuantity
        mockStorage.set(`resource-${resourceId}`, resource)
        mockStorage.set(`allocation-${missionId}-${resourceId}`, {
          "allocated-quantity":
              (mockStorage.get(`allocation-${missionId}-${resourceId}`)?.["allocated-quantity"] || 0) + allocateQuantity,
        })
        return { success: true }
      case "get-resource":
        return { success: true, value: mockStorage.get(`resource-${args[0]}`) }
      case "get-resource-allocation":
        return { success: true, value: mockStorage.get(`allocation-${args[0]}-${args[1]}`) }
      default:
        return { success: false, error: "Method not found" }
    }
  }
  
  it("should add a resource", () => {
    const result = mockContractCall("add-resource", ["Fuel", 1000], "CONTRACT_OWNER")
    expect(result.success).toBe(true)
    expect(result.value).toBe(1)
  })
  
  it("should allocate a resource", () => {
    mockContractCall("add-resource", ["Fuel", 1000], "CONTRACT_OWNER")
    const result = mockContractCall("allocate-resource", [1, 1, 500], "scientist1")
    expect(result.success).toBe(true)
  })
  
  it("should not allocate more than available", () => {
    mockContractCall("add-resource", ["Fuel", 1000], "CONTRACT_OWNER")
    const result = mockContractCall("allocate-resource", [1, 1, 1500], "scientist1")
    expect(result.success).toBe(false)
  })
  
  it("should get resource details", () => {
    mockContractCall("add-resource", ["Fuel", 1000], "CONTRACT_OWNER")
    const result = mockContractCall("get-resource", [1], "anyone")
    expect(result.success).toBe(true)
    expect(result.value.name).toBe("Fuel")
  })
  
  it("should get resource allocation", () => {
    mockContractCall("add-resource", ["Fuel", 1000], "CONTRACT_OWNER")
    mockContractCall("allocate-resource", [1, 1, 500], "scientist1")
    const result = mockContractCall("get-resource-allocation", [1, 1], "anyone")
    expect(result.success).toBe(true)
    expect(result.value["allocated-quantity"]).toBe(500)
  })
})

