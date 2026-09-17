"""
🟣 NIMMY AI Brain — Memory Router
===================================
"""

from typing import List, Optional
from fastapi import APIRouter, Query, HTTPException
from ..schemas import MemoryItem, MemoryCreate
from ..services.memory_vault import memory_vault

router = APIRouter()


@router.post("", response_model=MemoryItem)
async def create_memory(item: MemoryCreate) -> MemoryItem:
    """Store a new semantic memory node in the vault."""
    return memory_vault.add_memory(item)


@router.get("", response_model=List[MemoryItem])
async def get_memories(
    query: Optional[str] = Query(None, description="Search query for semantic similarity"),
    category: Optional[str] = Query(None, description="Filter by category"),
    limit: int = Query(20, ge=1, le=100),
) -> List[MemoryItem]:
    """List or search memory nodes in the semantic vault."""
    if query:
        return memory_vault.search(query=query, limit=limit, category=category)
    return memory_vault.list_all(limit=limit)


@router.delete("/{memory_id}")
async def delete_memory(memory_id: str):
    """Delete a memory node by ID."""
    deleted = memory_vault.delete(memory_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Memory node not found")
    return {"status": "success", "deleted_id": memory_id}
