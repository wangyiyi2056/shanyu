import uuid
from typing import Optional, List
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.routes.models import Route, Review
from app.routes.schemas import RouteCreate, RouteUpdate, ReviewCreate


async def create_route(db: AsyncSession, route_data: RouteCreate, user_id: str) -> Route:
    route_id = str(uuid.uuid4())
    route = Route(
        id=route_id,
        **route_data.model_dump(),
        created_by=user_id,
    )
    db.add(route)
    await db.commit()
    await db.refresh(route)
    return route


async def get_route_by_id(db: AsyncSession, route_id: str) -> Optional[Route]:
    result = await db.execute(
        select(Route).where(Route.id == route_id).options(selectinload(Route.reviews))
    )
    return result.scalar_one_or_none()


async def get_routes(
    db: AsyncSession,
    query: Optional[str] = None,
    difficulty: Optional[str] = None,
    max_duration: Optional[int] = None,
    max_distance: Optional[float] = None,
    tags: Optional[List[str]] = None,
    limit: int = 20,
    offset: int = 0,
) -> List[Route]:
    stmt = select(Route).options(selectinload(Route.reviews))

    if query:
        stmt = stmt.where(
            or_(
                Route.name.ilike(f"%{query}%"),
                Route.location.ilike(f"%{query}%"),
            )
        )

    if difficulty:
        stmt = stmt.where(Route.difficulty == difficulty)

    if max_duration:
        stmt = stmt.where(Route.estimated_duration <= max_duration)

    if max_distance:
        stmt = stmt.where(Route.distance <= max_distance)

    # Filter by tags (JSON contains)
    if tags:
        for tag in tags:
            stmt = stmt.where(Route.tags.contains([tag]))

    stmt = stmt.order_by(Route.rating.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def update_route(
    db: AsyncSession, route_id: str, route_data: RouteUpdate
) -> Optional[Route]:
    route = await get_route_by_id(db, route_id)
    if not route:
        return None

    update_data = route_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(route, field, value)

    await db.commit()
    await db.refresh(route)
    return route


async def delete_route(db: AsyncSession, route_id: str) -> bool:
    route = await get_route_by_id(db, route_id)
    if not route:
        return False
    await db.delete(route)
    await db.commit()
    return True


async def create_review(
    db: AsyncSession, route_id: str, user_id: str, review_data: ReviewCreate
) -> Review:
    review_id = str(uuid.uuid4())
    review = Review(
        id=review_id,
        route_id=route_id,
        user_id=user_id,
        **review_data.model_dump(),
    )
    db.add(review)

    # Update route rating
    route = await get_route_by_id(db, route_id)
    if route:
        route.review_count += 1
        # Calculate new average rating
        reviews = route.reviews
        total_rating = sum(r.rating for r in reviews) + review_data.rating
        route.rating = total_rating / (len(reviews) + 1)

    await db.commit()
    await db.refresh(review)
    return review


async def get_reviews_for_route(db: AsyncSession, route_id: str) -> List[Review]:
    result = await db.execute(
        select(Review).where(Review.route_id == route_id).order_by(Review.created_at.desc())
    )
    return list(result.scalars().all())


async def delete_review(db: AsyncSession, review_id: str) -> bool:
    result = await db.execute(select(Review).where(Review.id == review_id))
    review = result.scalar_one_or_none()
    if not review:
        return False

    # Update route rating
    route = await get_route_by_id(db, review.route_id)
    if route:
        route.review_count -= 1
        if route.review_count > 0:
            reviews = [r for r in route.reviews if r.id != review_id]
            total_rating = sum(r.rating for r in reviews)
            route.rating = total_rating / len(reviews)
        else:
            route.rating = 0.0

    await db.delete(review)
    await db.commit()
    return True