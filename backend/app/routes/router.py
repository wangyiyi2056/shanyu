from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, List

from app.database import get_db
from app.auth.router import get_current_user
from app.routes.schemas import (
    RouteCreate,
    RouteUpdate,
    RouteResponse,
    ReviewCreate,
    ReviewResponse,
)
from app.routes.service import (
    create_route,
    get_route_by_id,
    get_routes,
    update_route,
    delete_route,
    create_review,
    get_reviews_for_route,
    delete_review,
)

router = APIRouter(prefix="/routes", tags=["routes"])


@router.get("", response_model=List[RouteResponse])
async def list_routes(
    query: Optional[str] = Query(None),
    difficulty: Optional[str] = Query(None),
    max_duration: Optional[int] = Query(None),
    max_distance: Optional[float] = Query(None),
    tags: Optional[str] = Query(None),  # comma-separated
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    """List routes with optional filtering."""
    tag_list = tags.split(",") if tags else None
    routes = await get_routes(
        db,
        query=query,
        difficulty=difficulty,
        max_duration=max_duration,
        max_distance=max_distance,
        tags=tag_list,
        limit=limit,
        offset=offset,
    )
    return [RouteResponse.model_validate(r) for r in routes]


@router.get("/{route_id}", response_model=RouteResponse)
async def get_route(
    route_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Get route by ID."""
    route = await get_route_by_id(db, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found",
        )
    return RouteResponse.model_validate(route)


@router.post("", response_model=RouteResponse, status_code=status.HTTP_201_CREATED)
async def create_new_route(
    route_data: RouteCreate,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Create a new route."""
    route = await create_route(db, route_data, user.id)
    return RouteResponse.model_validate(route)


@router.put("/{route_id}", response_model=RouteResponse)
async def update_existing_route(
    route_id: str,
    route_data: RouteUpdate,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Update an existing route."""
    route = await get_route_by_id(db, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found",
        )
    if route.created_by != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this route",
        )
    updated_route = await update_route(db, route_id, route_data)
    return RouteResponse.model_validate(updated_route)


@router.delete("/{route_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_existing_route(
    route_id: str,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Delete a route."""
    route = await get_route_by_id(db, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found",
        )
    if route.created_by != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this route",
        )
    await delete_route(db, route_id)


@router.get("/{route_id}/reviews", response_model=List[ReviewResponse])
async def get_route_reviews(
    route_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Get reviews for a route."""
    reviews = await get_reviews_for_route(db, route_id)
    return [ReviewResponse.model_validate(r) for r in reviews]


@router.post("/{route_id}/reviews", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def create_route_review(
    route_id: str,
    review_data: ReviewCreate,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Create a review for a route."""
    route = await get_route_by_id(db, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found",
        )
    review = await create_review(db, route_id, user.id, review_data)
    return ReviewResponse.model_validate(review)


@router.delete("/{route_id}/reviews/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_route_review(
    route_id: str,
    review_id: str,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user),
):
    """Delete a review."""
    # Verify route exists
    route = await get_route_by_id(db, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found",
        )
    # Delete review (service checks ownership)
    deleted = await delete_review(db, review_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found",
        )